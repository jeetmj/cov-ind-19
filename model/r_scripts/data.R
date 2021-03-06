library(tidyverse)
library(vroom)

start.date <- as.Date("2020-03-01")

countries <- c("France", "Germany", "India", "Iran", "Italy",
               "Korea, South", "US", "China")

jhu.path <- paste0("~/COVID-19/csse_covid_19_data/csse_covid_19_time_series")

jhu.files <- list(
    Case      = paste0(jhu.path, "/time_series_covid19_confirmed_global.csv"),
    Recovered = paste0(jhu.path, "/time_series_covid19_recovered_global.csv"),
    Death     = paste0(jhu.path, "/time_series_covid19_deaths_global.csv")
)

data <- reduce(imap(jhu.files,
    function(file, var)
    {
        vroom(file) %>%
        select(Country = matches("Country"), matches("[0-9]+")) %>%
        filter(Country %in% countries) %>%
        mutate(Country = as.factor(case_when(
            Country == "Korea, South" ~  "South Korea",
            TRUE ~ Country))
        ) %>%
        group_by(Country) %>%

        # Since we don't care about counts in each state we collapse into a
        # single count per country of interest.
        summarise_all(sum, na.rm = T) %>%
        gather(matches("[0-9]+"), key = "Date", value = !!var) %>%
        mutate(Date = as.Date(Date, format = "%m/%d/%y")) %>%
        group_by(Date, )
        # filter(Date >= start.date - 1)
    }
), ~ left_join(.x, .y)) %>%
arrange(Country, Date) %>%
vroom_write(path = paste0("~/cov-ind-19-data/", Sys.Date(), "/jhu_data.csv"))

# mutate_at(vars(Case, Recovered, Death), list(function(x) {
#     y <- x - lag(x)
#     ifelse(y < 0, 0, y)
# })) %>%
# filter(Date >= start.date) %>%
# gather(Case, Recovered, Death, key = Type, value = Count) %>%
# mutate(Date = as.factor(format(Date, format = "%b %d")))
