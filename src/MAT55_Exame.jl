module MAT55_Exame

using DataStructures: OrderedDict
using Statistics
import TimeSeries as TS
import MarketData as MD
import Dates as DT
import HTTP
import Gumbo
using DataFrames
using ShiftedArrays
using Cascadia

export create_returns, get_statistics

const wikipedia_sp500_link = "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"

function scrape_wikipedia_table()::DataFrame
    sp500_page = HTTP.get(wikipedia_sp500_link)::HTTP.Response
    parsed_page = Gumbo.parsehtml(String(sp500_page.body))::Gumbo.HTMLDocument
    # selecionar os constiuintes do s&p 500
    match = eachmatch(sel"#constituents", parsed_page.root)::Vector{Gumbo.HTMLNode}
    # pegar os nomes das colunas
    colnames = String[]
    # dict como se fosse um DataFrame
    # chave: nome da coluna
    # valor: valores nas colunas
    dict_table = OrderedDict{String, Vector{String}}()
    # parse das linhas:
    rows = eachmatch(sel"tr", match[1])::Vector{Gumbo.HTMLNode}
    for (i, row) in enumerate(rows)
        if (i == 1) # header
            header = eachmatch(sel"th", row)::Vector{Gumbo.HTMLNode}
            for col in header
                colname = strip(nodeText(col))::SubString{String}
                push!(colnames, colname)
            end
            for name in colnames
                dict_table[name] = Vector{String}()
            end
        else
            row_vals = eachmatch(sel"td", row)::Vector{Gumbo.HTMLNode}
            for (j, node) in enumerate(row_vals)
                node_text = strip(nodeText(node))::SubString{String}
                col = colnames[j]
                push!(dict_table[col], node_text)
            end
        end
    end
    dataframe = DataFrame(dict_table)
    dataframe
end

function get_data(ticker::String, start_dt::DT.Date)::DataFrame
    sleep(0.21)
    end_dt = DT.now()::DT.DateTime
    try
        yahoo_data = MD.yahoo(
            ticker,
            MD.YahooOpt(
                period1 = DT.DateTime(start_dt),
                period2 = end_dt,
                interval = "1d"
            )
        )::TS.TimeArray
        df = DataFrame(yahoo_data)
        df
    catch e
        showerror(stdout, e)
        return DataFrame()
    end
end

function create_returns()
    tickers = scrape_wikipedia_table()
    # transform para colocar todas as strings em yyyy-mm-dd
    # usando regex
    exp = r"\d{4}-\d{2}-\d{2}"
    transform!(
        tickers,
        "Date first added" => ByRow(x -> !isnothing(match(exp, x)) ? match(exp, x).match : x) => "Date first added"
    )
    # transformar em objeto date
    transform!(
        tickers,
        "Date first added" => ByRow(x -> DT.Date(x, DT.dateformat"y-m-d")) => "Date first added"
    )
    maxdate = combine(tickers, "Date first added" => maximum)[1, 1]
    ticker_names = tickers[!, "Symbol"]
    df = DataFrame()
    for name in ticker_names
        ticker_data = get_data(name, maxdate)
        if isempty(ticker_data)
            continue
        end
        transform!(ticker_data, :Close => lag => :Close_lag)
        ticker_data = dropmissing(ticker_data, :Close_lag)
        transform!(ticker_data, [:Close, :Close_lag] => ((x, y) -> (x ./ y .- 1)) => :returns)
        if !("date" in names(df))
            insertcols!(df, (["date", name] .=> [ticker_data[!, :timestamp], ticker_data[!, :returns]])...)
        else
            insertcols!(df, name => ticker_data[!, :returns])
        end
    end
    df
end

@doc """
`get_statistics`

Returns the mean vector `μ`, covariance matrix `Σ`, names of the tickers `tickers` and the dates of each return for the assets `dates_df` 
in the input `DataFrame` as a tuple, in this order.
"""
function get_statistics(df::DataFrame)::Tuple{Vector{Float64}, Matrix{Float64}, Vector{String}, DataFrame}
    tickers = names(select(df, Not(:date)))
    dates_df = select(df, :date)
    dists = Matrix(select(df, Not(:date)))
    μ = vec(mean(dists, dims=1))
    Σ = cov(dists)
    μ, Σ, tickers, dates_df
end

function create_linear_model(Σ::Matrix{Float64})::Tuple{Matrix{Float64}, Vector{Float64}}
    n = size(Σ, 1)
    A = [2 .* Σ ones(n); ones(n)' 0]
    b = [zeros(n); 1]
    A, b
end

end # module
