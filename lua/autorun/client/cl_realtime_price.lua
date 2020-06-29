if (!BM2CONFIG) then return end
if (!BM2CONFIG.RealTimePrice) then
    if timer.Exists("BM2REALTIMEAPI") then
        timer.Destroy("BM2REALTIMEAPI")
    end
end

function BM2CONFIG:RefreshPrice()

    http.Fetch("https://blockchain.info/ticker",

        function(body, len, headers, code)

            local tbl = util.JSONToTable(body)[BM2CONFIG.BitcoinCurrency] or "USD"

            BM2CONFIG.BitcoinValue = tbl.buy

        end,

        function(error)

            return chat.AddText(Color(243, 156, 18), "[Bitcoins API]", color_white, " Failed to connect to the API!")

        end

    )

end

timer.Create("BM2REALTIMEAPI", BM2CONFIG.RefreshRate * 60, 0, function()

    BM2CONFIG.RefreshPrice()

end)

concommand.Add("bitcoins_refresh", function()

    if (BM2CONFIG.RealTimePrice) then

        BM2CONFIG.RefreshPrice()
        MsgC(Color(243, 156, 18), "[Bitcoins API]", color_white, " New Bitcoin Price : ", Color(243, 156, 18), (BM2CONFIG.BitcoinCurrency or "USD") .. " " .. (BM2CONFIG.BitcoinValue), color_white, " !")

    else

        MsgC(Color(243, 156, 18), "[Bitcoins API]", color_white, " The realtime Bitcoin Price isn't activated!")

    end

end)