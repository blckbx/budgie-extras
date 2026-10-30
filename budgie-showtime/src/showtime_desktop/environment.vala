namespace ShowTime {
    // Read configuration once, before the window starts its update thread.
    internal string load_bitcoin_api_url () {
        string? value = Environment.get_variable("SHOWTIME_BITCOIN_API_URL");
        if (value == null || value.strip() == "") {
            string? path = Environment.get_variable("SHOWTIME_ENV_FILE");
            if (path == null || path == "") {
                path = Path.build_filename(Environment.get_user_config_dir(),
                                           "budgie-showtime", ".env");
                if (!FileUtils.test(path, FileTest.EXISTS)) {
                    path = Path.build_filename(Environment.get_current_dir(), ".env");
                }
            }
            if (FileUtils.test(path, FileTest.EXISTS)) {
                try {
                    string contents;
                    FileUtils.get_contents(path, out contents);
                    foreach (string raw_line in contents.split("\n")) {
                        string line = raw_line.strip();
                        if (line.has_prefix("#")) {
                            continue;
                        }
                        string[] assignment = line.split("=", 2);
                        if (assignment.length != 2 ||
                            assignment[0].strip() != "SHOWTIME_BITCOIN_API_URL") {
                            continue;
                        }
                        value = assignment[1].strip();
                        if (value.length >= 2 &&
                            ((value.has_prefix("\"") && value.has_suffix("\"")) ||
                             (value.has_prefix("'") && value.has_suffix("'")))) {
                            value = value.substring(1, value.length - 2);
                        }
                    }
                } catch (FileError e) {
                    warning("Could not read Showtime .env: %s", e.message);
                }
            }
        }
        if (value == null || value.strip() == "") {
            warning("Set SHOWTIME_BITCOIN_API_URL in the environment or Showtime .env");
            return "https://IP:PORT";
        }
        value = value.strip();
        while (value.has_suffix("/")) {
            value = value.substring(0, value.length - 1);
        }
        return value;
    }
}
