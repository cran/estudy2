source("helpers.R")

ui <- shiny::fluidPage(

    shinyFeedback::useShinyFeedback(),

    shiny::titlePanel(
        title = shiny::div(
            "Event study",
            shiny::img(src = "logo.png", height = 50, align = "right")
        ),
        windowTitle = "Event study"
    ),

    shiny::tags$hr(),

    shiny::sidebarLayout(

        shiny::sidebarPanel(

            shiny::textInput(
                "tickers",
                "List tickers separated by comma:",
                value = "AMZN, ZM, UBER, NFLX, SHOP, FB, UPWK"
            ),

            shiny::dateRangeInput(
                "date_range",
                "Select start and end date:",
                start = "2019-04-01",
                end = "2020-04-01"
            ),

            shinyWidgets::awesomeRadio(
                "price_type",
                "Select the price type:",
                choices = c("Close", "Open")
            ),

            shiny::tags$hr(),

            shinyWidgets::awesomeRadio(
                "compounding",
                "Select the compounding type:",
                choices = c(
                    "Discrete" = "discrete",
                    "Continuous" = "continuous"
                )
            ),

            shinyWidgets::awesomeRadio(
                "multi_day",
                "Take into account rates between\n more than one day?",
                choices = c(
                    "Yes" = TRUE,
                    "No" = FALSE
                )
            ),

            shiny::tags$hr(),

            shinyWidgets::awesomeRadio(
                "model",
                "Select the market model:",
                choices = c(
                    "Mean-adjusted returns model" = "mean_adj",
                    "Market-adjusted returns model" = "mrkt_adj",
                    "Single index market\n model" = "sim"
                )
            ),

            shiny::conditionalPanel(
                condition =
                    "input.model == 'mrkt_adj' | input.model == 'sim'",
                shiny::tags$hr(),
                shiny::textInput(
                    "index",
                    "Specify the ticker of the index:",
                    value = "^GSPC"
                ),
            ),

            shiny::tags$hr(),

            shiny::dateRangeInput(
                "estmation_window",
                "Select the estimation window:",
                start = "2019-04-01",
                end = "2020-03-13"
            ),

            shiny::dateRangeInput(
                "event_window",
                "Select the event window:",
                start = "2020-03-16",
                end = "2020-03-20"
            ),

            shiny::column(
                width = 12,
                shiny::actionButton(
                    "calculate",
                    "Calculate",
                    icon = shiny::icon("calculator"),
                    width = "100%"

                ),
                align = "center"
            )

        ),

        mainPanel(
            shiny::tabsetPanel(
                shiny::tabPanel(
                    title = "Parametric test",
                    DT::dataTableOutput("parametric_table")

                ),
                shiny::tabPanel(
                    title = "Nonparametric test",
                    DT::dataTableOutput("nonparametric_table")
                )
            )
        )
    ),

    theme = bslib::bs_theme(version = 4, bootswatch = "solar")
)

server <- function(input, output, session) {

    prices <- shiny::eventReactive(input$calculate, {

        shinyFeedback::feedbackWarning(
            "date_range",
            input$date_range[1] >= input$date_range[2],
            "Please make sure the start date is lower than the end date."
        )

        shiny::req(input$date_range[1] < input$date_range[2])

        shinyFeedback::feedbackWarning(
            "tickers",
            input$tickers == "",
            "Please specify tickers separated by comma."
        )

        shiny::req(input$tickers)

        tickers <- input$tickers %>%
            stringr::str_split(",") %>%
            unlist() %>%
            stringr::str_trim(side = "both")

        prices_list <- list()

        withProgress(message = "Downloading prices...", {

            for (ticker in tickers) {

                prices_list[[ticker]] <- download_prices(
                    ticker,
                    start = input$date_range[1],
                    end = input$date_range[2],
                    quote = input$price_type,
                    retclass = "list"
                ) %>%
                    purrr::pluck(1)

                if (is.null(prices_list[[ticker]])) {
                    shiny::showNotification(
                        paste0(
                            "Could not retrieve prices for ",
                            ticker,
                            ". This security will be ignored."
                        ),
                        type = "warning"
                    )
                }

                incProgress(1 / length(tickers))

            }

        })

        shinyFeedback::feedbackWarning(
            "tickers",
            length(prices_list) < 2,
            "Please make sure that at least two valid tickers are specified."
        )

        shiny::req(length(prices_list) > 1)

        prices_list

    })

    rates <- shiny::eventReactive(input$calculate, {
        estudy2::get_rates_from_prices(
            prices = prices(),
            quote = input$price_type,
            multi_day = input$multi_day,
            compounding = input$compounding
        )
    })

    rates_indx <- shiny::eventReactive(input$calculate, {

        if (input$model != "mean_adj") {

            shinyFeedback::feedbackWarning(
                "index",
                input$index == "",
                "Please specify a valid ticker for the market index."
            )

            shiny::req(input$index)

            prices_indx <- download_prices(
                input$index,
                start = input$date_range[1],
                end = input$date_range[2],
                quote = input$price_type,
                retclass = "list"
            )

            shinyFeedback::feedbackWarning(
                "index",
                is.null(prices_indx),
                "Please specify a valid ticker for the market index."
            )

            shiny::req(!is.null(prices_indx))

            estudy2::get_rates_from_prices(
                prices_indx,
                quote = input$price_type,
                multi_day = input$multi_day,
                compounding = input$compounding
            )
        } else {
            NULL
        }
    })

    stock_returns <- shiny::eventReactive(input$calculate, {
        estudy2::apply_market_model(
            rates = rates(),
            regressor = rates_indx(),
            same_regressor_for_all = TRUE,
            market_model = input$model,
            estimation_method = "ols",
            estimation_start = input$estmation_window[1],
            estimation_end = input$estmation_window[2]
        )
    })

    output$parametric_table <- DT::renderDataTable({

        estudy2::parametric_tests(
            list_of_returns = stock_returns(),
            event_start = isolate(input$event_window[1]),
            event_end = isolate(input$event_window[2])
        ) %>%
            beautify() %>%
            formattable::as.datatable(options = list(scrollX = TRUE))

    })

    output$nonparametric_table <- DT::renderDataTable({

        estudy2::nonparametric_tests(
            list_of_returns = stock_returns(),
            event_start = isolate(input$event_window[1]),
            event_end = isolate(input$event_window[2])
        ) %>%
            beautify() %>%
            formattable::as.datatable(options = list(scrollX = TRUE))

    })


    # Interactions between UI elements
    #---------------------------------------------------------------------------

    # The priority argument had to be added, since the default start of
    # input$event_window was set to input$estmation_window[2] + 1, before
    # input$estmation_window was updated with
    # input$date_range[1] + estimation_window_length.

    # I split setting min/max and start/end since I did not want to overwrite
    # default values of start/end at launch (ignoreInit = TRUE), but
    # still wanted to set min/max if input$date_range is changed.

    # Update boundaries of input$estmation_window
    shiny::observeEvent(
        input$date_range,
        shiny::updateDateRangeInput(
            session = session,
            inputId = "estmation_window",
            min = input$date_range[1],
            max = input$date_range[2]
        ),
        priority = 4
    )

    # Update values of input$estmation_window (ignoring initialization)
    shiny::observeEvent(
        input$date_range, {

            estimation_window_length <- 2 / 3 *
                as.numeric(input$date_range[2] - input$date_range[1])

            shiny::updateDateRangeInput(
                session = session,
                inputId = "estmation_window",
                start = input$date_range[1],
                end = input$date_range[1] + estimation_window_length
            )
        },
        priority = 3,
        ignoreInit = TRUE
    )


    # Update boundaries of input$event_window
    observe({
        shiny::updateDateRangeInput(
            session = session,
            inputId = "event_window",
            min = input$estmation_window[2] + 1,
            max = input$date_range[2]
        )},
        priority = 2
    )


    # Update values of input$event_window (ignoring initialization)
    shiny::observeEvent(
        input$estmation_window,
        shiny::updateDateRangeInput(
            session = session,
            inputId = "event_window",
            start = input$estmation_window[2] + 1,
            end = input$date_range[2]
        ),
        priority = 1,
        ignoreInit = TRUE
    )

    shiny::observeEvent(input$calculate, {
        shiny::updateActionButton(
            session = session,
            inputId = "calculate",
            label = "Update",
            icon = shiny::icon("redo")
        )
    })

    #---------------------------------------------------------------------------
    # Bookmarking

    shiny::observe({
        shiny::reactiveValuesToList(input)
        session$doBookmark()
    })

    shiny::onBookmarked(shiny::updateQueryString)

}

shiny::shinyApp(ui = ui, server = server, enableBookmarking = "url")
