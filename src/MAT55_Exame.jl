module MAT55_Exame
import TimeSeries as TS
import MarketData as MD
import DataFrames as DF
import Dates as DT


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


end # module
