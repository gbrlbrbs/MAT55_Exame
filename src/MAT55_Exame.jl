module MAT55_Exame

using DataStructures: OrderedDict
import TimeSeries as TS
import MarketData as MD
import DataFrames as DF
import Dates as DT
import HTTP
import Gumbo
using Cascadia

export scrape_wikipedia_table, get_data

const wikipedia_sp500_link = "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"

function get_data(ticker::String)::DF.DataFrame
    start_dt::DT.DateTime = DT.DateTime(2016)  # 2016-01-01
    end_dt::DT.DateTime = DT.now()
    yahoo_data::TS.TimeArray = MD.yahoo(
        ticker,
        MD.YahooOpt(
            period1 = start_dt,
            period2 = end_dt,
            interval = "1d"
        )
    )
    df::DF.DataFrame = DF.DataFrame(yahoo_data)
    return df
end

function scrape_wikipedia_table()::DF.DataFrame
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
    dataframe = DF.DataFrame(dict_table)
    dataframe
end

# function get_tickers(start_date::DT.Date)

# end

end # module
