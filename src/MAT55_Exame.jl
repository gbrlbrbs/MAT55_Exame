module MAT55_Exame
using DataStructures : OrderedDict
import TimeSeries as TS
import MarketData as MD
import DataFrames as DF
import Dates as DT
import HTTP
import Gumbo
using Cascadia

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

function scrape_wikipedia_tables()::Vector{DF.DataFrame}
    sp500_page = HTTP.get(wikipedia_sp500_link)::HTTP.Response
    parsed_page = Gumbo.parsehtml(String(sp500_page.body))::Gumbo.HTMLDocument
    matches = eachmatch(sel"table", parsed_page.root)::Vector{Gumbo.HTMLNode}
    # cada match: um DataFrame
    tables = DF.DataFrame[]
    for m in matches
        # pegar os nomes das colunas
        colnames = String[]
        # como se fosse um DataFrame
        # chave: nome da coluna
        # valor: valores nas colunas
        dict_table = OrderedDict{String, Vector{String}}()
        # parse das linhas:
        rows = eachmatch(sel"tr", m)::Vector{Gumbo.HTMLNode}
        for (i, row) in enumerate(rows)
            if (i == 1) # header
                header = eachmatch(sel"th", row)::Vector{Gumbo.HTMLNode}
                for col in header
                    col_name = strip(nodeText(col))::String
                    test_colname = col_name
                    k = 2
                    while (test_colname in colnames)
                        test_colname = col_name + "_$k"
                        k += 1
                    end
                    push!(colnames, test_colname)
                end
            else
                row_vals = eachmatch(sel"th", row)::Vector{Gumbo.HTMLNode}
                for (j, node) in enumerate(row_vals)
                    node_text = strip(nodeText(node))::String
                    col = colnames[j]
                    push!(dict_table[col], node_text)
                end
            end
        end
        dataframe = DF.DataFrame(dict_table)
        push!(tables, dataframe)
    end
    tables
end

# function get_tickers(start_date::DT.Date)

# end

end # module
