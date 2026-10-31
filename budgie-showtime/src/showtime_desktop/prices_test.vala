private class TickerSession : Soup.Session {
    public int calls = 0;
    public uint status = Soup.Status.OK;
    public string body = """{"result":{"XXBTZUSD":{"c":["100000.50","1"]},"XXBTZEUR":{"c":["90000.25","1"]}}}""";

    public override uint send_message (Soup.Message message) {
        calls++;
        message.set_status(status);
        message.set_response("application/json", Soup.MemoryUse.COPY, body.data);
        message.response_body.flatten();
        return message.status_code;
    }
}

void main (string[] args) {
    Test.init(ref args);
    // Request failures are expected in these outage scenarios.
    Log.set_always_fatal(LogLevelFlags.LEVEL_ERROR | LogLevelFlags.LEVEL_CRITICAL);
    Test.add_func("/prices/success-outage-and-recovery", () => {
        var ticker = new ShowTime.PriceTicker();
        var session = new TickerSession();
        ticker.refresh(session);
        assert(session.calls == 1);
        assert(ticker.usd == 100000.50 && ticker.eur == 90000.25 && !ticker.stale);
        session.status = Soup.Status.SERVICE_UNAVAILABLE;
        ticker.refresh(session);
        assert(ticker.usd == 100000.50 && ticker.eur == 90000.25 && ticker.stale);
        session.status = Soup.Status.OK;
        ticker.refresh(session);
        assert(!ticker.stale);
    });
    Test.add_func("/prices/unavailable-at-startup", () => {
        var ticker = new ShowTime.PriceTicker();
        var session = new TickerSession();
        session.status = Soup.Status.CANT_CONNECT;
        ticker.refresh(session);
        assert(ticker.usd == 0 && ticker.eur == 0 && ticker.stale);
    });
    Test.add_func("/prices/empty-response-unavailable", () => {
        var ticker = new ShowTime.PriceTicker();
        var session = new TickerSession();
        session.body = "";
        ticker.refresh(session);
        assert(session.calls == 1 && ticker.usd == 0 && ticker.eur == 0 && ticker.stale);
    });
    Test.add_func("/prices/invalid-responses-preserve-cache", () => {
        var ticker = new ShowTime.PriceTicker();
        try {
            ticker.load_prices("""{"result":{"XXBTZUSD":{"c":["100000.75"]},"XXBTZEUR":{"c":["90000"]}}}""");
        } catch (Error e) {
            Test.fail();
        }
        string[] invalid = {
            "<html>blocked</html>", "null", "[]", "{}",
            """{"result":{"XXBTZUSD":{"c":["0"]},"XXBTZEUR":{"c":["90000"]}}}""",
            """{"result":{"XXBTZUSD":{"c":["100000"]},"XXBTZEUR":{"c":["-1"]}}}""",
            """{"result":{"XXBTZUSD":{"c":["100000"]},"XXBTZEUR":{"c":[90000]}}}""",
            """{"result":{"XXBTZUSD":{"c":["100000"]},"XXBTZEUR":{"c":[]}}}""",
            """{"result":{"XXBTZUSD":{"c":["100000"]},"XXBTZEUR":{"c":["NaN"]}}}""",
            """{"result":{"XXBTZUSD":{"c":["100000"]}}}"""
        };
        foreach (string body in invalid) {
            try {
                ticker.load_prices(body);
                Test.fail();
            } catch (Error e) {
                assert(ticker.usd == 100000.75 && ticker.eur == 90000);
            }
        }
        var session = new TickerSession();
        session.body = """{"error":["Unavailable"],"result":{}}""";
        ticker.refresh(session);
        assert(ticker.usd == 100000.75 && ticker.eur == 90000 && ticker.stale);
    });
    Test.run();
}
