module MAT55_Exame
import TimeSeries as TS
import MarketData as MD
import DataFrames as DF
import Dates as DT
import HTTP


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

# function scrape_wikipedia_table()

# end

# function get_tickers(start_date::DT.Date)

# end

end # module
