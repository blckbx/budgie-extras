namespace ShowTime {
    internal class PriceTicker : GLib.Object {
        public double usd { get; private set; default = 0; }
        public double eur { get; private set; default = 0; }
        public bool stale { get; private set; default = true; }

        private Json.Object require_object (Json.Object parent, string name) throws GLib.Error {
            var node = parent.get_member(name);
            if (node == null || node.get_node_type() != Json.NodeType.OBJECT) {
                throw new IOError.INVALID_DATA("Missing ticker object: %s", name);
            }
            return node.get_object();
        }

        private double kraken_price (Json.Object result, string pair) throws GLib.Error {
            var quote = require_object(result, pair);
            var node = quote.get_member("c");
            if (node == null || node.get_node_type() != Json.NodeType.ARRAY ||
                node.get_array().get_length() == 0) {
                throw new IOError.INVALID_DATA("Missing last trade for %s", pair);
            }
            var last = node.get_array().get_element(0);
            double price = 0;
            if (last.get_node_type() != Json.NodeType.VALUE ||
                last.get_value_type() != typeof(string) ||
                !double.try_parse(last.get_string(), out price)) {
                throw new IOError.INVALID_DATA("Invalid last trade for %s", pair);
            }
            return price;
        }

        // Commit both prices together so malformed responses preserve the cache.
        internal void load_prices (string data) throws GLib.Error {
            var parser = new Json.Parser();
            parser.load_from_data(data);
            var root = parser.get_root();
            if (root == null || root.get_node_type() != Json.NodeType.OBJECT) {
                throw new IOError.INVALID_DATA("Ticker response is not an object");
            }
            var obj = root.get_object();
            var result = require_object(obj, "result");
            double next_usd = kraken_price(result, "XXBTZUSD");
            double next_eur = kraken_price(result, "XXBTZEUR");
            if (!(next_usd >= 1 && next_usd <= int.MAX) ||
                !(next_eur >= 1 && next_eur <= int.MAX)) {
                throw new IOError.INVALID_DATA("Ticker prices are outside the supported range");
            }
            usd = next_usd;
            eur = next_eur;
            stale = false;
        }

        public void refresh (Soup.Session session) {
            const string url = "https://api.kraken.com/0/public/Ticker?pair=XBTUSD,XBTEUR";
            stale = true;
            var message = new Soup.Message("GET", url);
            session.send_message(message);
            if (message.status_code != Soup.Status.OK) {
                warning("Price request to %s failed: %u %s", url,
                        message.status_code, message.reason_phrase);
                return;
            }
            if (message.response_body.length == 0) {
                warning("Empty price response from %s", url);
                return;
            }
            try {
                load_prices((string) message.response_body.data);
            } catch (GLib.Error e) {
                warning("Invalid price response from %s: %s", url, e.message);
            }
        }
    }
}
