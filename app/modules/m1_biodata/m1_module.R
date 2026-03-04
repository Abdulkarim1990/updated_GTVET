# =============================================================
# GTVET-IDMS  Module M1 — Institutional Bio-Data & Enrolment
# Maps to: Technical Institute Semester's Reporting Template
#   Sheets: Bio-Data, Enrolment, PWSN_Students, WEL (summary),
#           Exam, Graduate List, Challenges, Recommendation
# =============================================================

# ------ UI ---------------------------------------------------

m1UI <- function(id) {
  ns <- NS(id)
  tagList(
    h2("Module M1 — Institutional Bio-Data & Enrolment"),
    p(class = "text-muted",
      "Complete all tabs below and click ", strong("Submit for Review"),
      " when ready. You may save progress at any time."),

    # Submission period selector & status banner
    fluidRow(
      column(3, selectInput(ns("sel_semester"), "Semester",
                            choices = c("Semester 1" = 1, "Semester 2" = 2))),
      column(3, uiOutput(ns("academic_year_display"))),
      column(6, uiOutput(ns("submission_status_banner")))
    ),

    # Tab panels mirroring the Excel sheets
    tabsetPanel(
      id = ns("m1_tabs"),

      # ---- Tab 1: Bio-Data ------------------------------------
      tabPanel("Bio-Data",
        br(),
        fluidRow(
          column(6,
            h4("Reporting Period"),
            uiOutput(ns("bio_reporting_month_ui")),
            h4("Principal Contact"),
            textInput(ns("bio_principal_name"),  "Principal's Name"),
            textInput(ns("bio_principal_mobile"), "Principal's Mobile Number"),
            textInput(ns("bio_principal_email"),  "Principal's Personal Email")
          ),
          column(6,
            h4("Institute Details (pre-filled from your account)"),
            uiOutput(ns("bio_institution_info")),
            hr(),
            h4("Infrastructure"),
            fluidRow(
              column(6,
                selectInput(ns("bio_has_sickbay"),  "Sickbay?",
                            choices = c("","Yes"="TRUE","No"="FALSE")),
                selectInput(ns("bio_has_library"),  "Library?",
                            choices = c("","Yes"="TRUE","No"="FALSE")),
                selectInput(ns("bio_library_stocked"), "Library stocked with books?",
                            choices = c("","Yes"="TRUE","No"="FALSE"))
              ),
              column(6,
                selectInput(ns("bio_has_ict_lab"),     "ICT Lab?",
                            choices = c("","Yes"="TRUE","No"="FALSE")),
                selectInput(ns("bio_ict_lab_equipped"), "ICT Lab well equipped?",
                            choices = c("","Yes"="TRUE","No"="FALSE"))
              )
            )
          )
        ),
        fluidRow(
          column(12,
            h4("Enrolment Summary (auto-calculated)"),
            fluidRow(
              column(3, numericInput(ns("bio_day_enrolment"),     "Day Enrolment (Yr.1)",     0, min=0)),
              column(3, numericInput(ns("bio_boarding_enrolment"),"Boarding Enrolment (Yr.1)",0, min=0)),
              column(3, numericInput(ns("bio_fee_paying"),        "Fee Paying Enrolment",     0, min=0)),
              column(3, uiOutput(ns("bio_total_enrolment")))
            )
          )
        ),
        fluidRow(
          column(12,
            textAreaInput(ns("bio_remarks"), "Additional Remarks", rows = 3)
          )
        )
      ),

      # ---- Tab 2: Enrolment -----------------------------------
      tabPanel("Enrolment",
        br(),
        p("Enter enrolment figures for each programme and year of study.",
          class = "text-muted"),
        fluidRow(
          column(3,
            actionButton(ns("enrol_add_row"), "Add Programme Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          ),
          column(3,
            uiOutput(ns("enrol_programme_filter"))
          )
        ),
        br(),
        uiOutput(ns("enrolment_rows_ui")),
        br(),
        uiOutput(ns("enrolment_totals"))
      ),

      # ---- Tab 3: PWSN ----------------------------------------
      tabPanel("PWSN Students",
        br(),
        p("Persons With Special Needs — enter per programme, year, and impairment type.",
          class = "text-muted"),
        fluidRow(
          column(3,
            actionButton(ns("pwsn_add_row"), "Add PWSN Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("pwsn_rows_ui"))
      ),

      # ---- Tab 4: WEL Summary ---------------------------------
      tabPanel("WEL Summary",
        br(),
        p("WEL placement summary — number due and placed per programme.",
          class = "text-muted"),
        fluidRow(
          column(3,
            actionButton(ns("wel_add_row"), "Add WEL Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("wel_rows_ui")),
        hr(),
        h4("Industry Partners"),
        fluidRow(
          column(3,
            actionButton(ns("ind_add_row"), "Add Industry Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("industry_rows_ui"))
      ),

      # ---- Tab 5: Examination ---------------------------------
      tabPanel("Examination",
        br(),
        fluidRow(
          column(3, numericInput(ns("exam_year"), "Examination Year",
                                 value = as.integer(format(Sys.Date(), "%Y")),
                                 min = 2000, max = 2100, step = 1)),
          column(3, selectInput(ns("exam_month"), "Examination Month",
                                choices = c("", month_choices)))
        ),
        fluidRow(
          column(3,
            actionButton(ns("exam_add_row"), "Add Exam Row",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("exam_rows_ui"))
      ),

      # ---- Tab 6: Graduate List --------------------------------
      tabPanel("Graduate List",
        br(),
        p("List all graduates for this reporting period.", class = "text-muted"),
        fluidRow(
          column(3,
            actionButton(ns("grad_add_row"), "Add Graduate",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("grad_rows_ui"))
      ),

      # ---- Tab 7: Challenges & Recommendations ----------------
      tabPanel("Challenges & Recommendations",
        br(),
        h4("Challenges"),
        fluidRow(
          column(3,
            actionButton(ns("chal_add_row"), "Add Challenge",
                         icon = icon("plus"), class = "btn-info btn-sm")
          )
        ),
        br(),
        uiOutput(ns("chal_rows_ui")),
        hr(),
        h4("Recommendations"),
        textAreaInput(ns("recommendations_text"),
                      "Recommendations (one per line)", rows = 6)
      )
    ),

    # ------ Action buttons ------------------------------------
    hr(),
    fluidRow(
      column(12,
        uiOutput(ns("validation_messages")),
        div(
          style = "display:flex; gap:10px;",
          actionButton(ns("btn_save_draft"), "Save Draft",
                       icon = icon("save"),   class = "btn btn-default"),
          actionButton(ns("btn_submit"),     "Submit for Review",
                       icon = icon("paper-plane"), class = "btn btn-success"),
          uiOutput(ns("save_feedback"))
        )
      )
    )
  )
}

# ------ Server -----------------------------------------------

m1Server <- function(id, pool, auth) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ---- State -----------------------------------------------
    current_submission <- reactiveVal(NULL)   # list(submission_id, status, version)
    enrolment_rows     <- reactiveVal(1L)
    pwsn_rows          <- reactiveVal(0L)
    wel_rows           <- reactiveVal(1L)
    industry_rows      <- reactiveVal(0L)
    exam_rows          <- reactiveVal(1L)
    grad_rows          <- reactiveVal(1L)
    chal_rows          <- reactiveVal(1L)

    # ---- Academic year display --------------------------------
    output$academic_year_display <- renderUI({
      div(class = "form-group",
        tags$label("Academic Year"),
        div(class = "form-control-static", strong(APP_CONFIG$current_ay))
      )
    })

    # ---- Institution info panel (school users see their own) --
    output$bio_institution_info <- renderUI({
      inst <- load_institutions(pool) |>
        dplyr::filter(institution_id == auth$institution_id)
      if (nrow(inst) == 0) return(p("Institution not found.", class = "text-danger"))
      tags$table(class = "table table-condensed",
        tags$tbody(
          tags$tr(tags$th("Institution"), tags$td(inst$institution_name[1])),
          tags$tr(tags$th("CSSPS Code"),  tags$td(inst$cssps_code[1])),
          tags$tr(tags$th("Region"),      tags$td(inst$region_name[1])),
          tags$tr(tags$th("Type"),        tags$td(inst$institution_type[1]))
        )
      )
    })

    output$bio_reporting_month_ui <- renderUI({
      selectInput(ns("bio_reporting_month"), "Reporting Month",
                  choices = c("", month_choices))
    })

    # ---- Submission status banner -----------------------------
    output$submission_status_banner <- renderUI({
      sub <- current_submission()
      if (is.null(sub)) {
        div(class = "alert alert-info",
            icon("info-circle"),
            " No submission yet for this period. Start entering data below.")
      } else {
        status_class <- switch(sub$status,
          Draft        = "info",
          Submitted    = "warning",
          `Under Review` = "warning",
          Approved     = "success",
          Returned     = "danger",
          "info")
        msg <- switch(sub$status,
          Returned = paste("Returned — Reason:", sub$return_reason),
          sub$status)
        div(class = paste("alert alert-", status_class, sep=""),
            icon("circle"), " Status: ", strong(msg),
            if (!is.null(sub$version) && sub$version > 1)
              span(class = "badge", paste("v", sub$version)))
      }
    })

    # ---- Load existing submission on semester change ----------
    observeEvent(list(input$sel_semester, auth$institution_id), {
      req(auth$logged_in, auth$institution_id)
      sub <- get_active_submission(
        pool, auth$institution_id, "M1",
        APP_CONFIG$current_ay, input$sel_semester)
      current_submission(sub)
      if (!is.null(sub)) {
        load_submission_data(sub$submission_id)
      }
    })

    # ---- Total enrolment computed display --------------------
    output$bio_total_enrolment <- renderUI({
      day  <- as.integer(input$bio_day_enrolment) %||% 0L
      brd  <- as.integer(input$bio_boarding_enrolment) %||% 0L
      fee  <- as.integer(input$bio_fee_paying) %||% 0L
      tot  <- day + brd + fee
      div(class = "form-group",
        tags$label("Total Enrolment (computed)"),
        div(class = "form-control-static well", strong(format(tot, big.mark=",")))
      )
    })

    # ---- Dynamic row generators ------------------------------

    # Enrolment rows
    output$enrolment_rows_ui <- renderUI({
      n   <- enrolment_rows()
      inst_progs <- load_institution_programmes(pool, auth$institution_id)
      prog_choices_inst <- c("Other (type below)" = 0,
                              setNames(inst_progs$programme_id, paste0(
                                "[", inst_progs$programme_code, "] ",
                                inst_progs$programme_name)))

      rows <- lapply(seq_len(n), function(i) {
        fluidRow(
          class = "enrol-row",
          column(1, tags$small(paste("#", i))),
          column(2, selectInput(ns(paste0("enrol_prog_", i)),   "Programme",
                                choices = prog_choices_inst, width="100%")),
          column(2, textInput(  ns(paste0("enrol_prog_ot_", i)),"Other programme name",
                                placeholder = "if 'Other' selected", width="100%")),
          column(1, selectInput(ns(paste0("enrol_yr_", i)),     "Year",
                                choices = c(1,2,3), width="100%")),
          column(1, numericInput(ns(paste0("enrol_cls_", i)),   "Classrooms", 0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("enrol_wks_", i)),   "Workshops",  0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("enrol_m_", i)),     "Male",       0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("enrol_f_", i)),     "Female",     0, min=0, width="100%")),
          column(1, div(class="form-group",
                        tags$label("Total"),
                        div(class="form-control-static",
                            uiOutput(ns(paste0("enrol_tot_", i)))))),
          column(1, actionButton(ns(paste0("enrol_del_", i)), "",
                                 icon=icon("trash"), class="btn btn-danger btn-xs",
                                 style="margin-top:25px;"))
        )
      })
      tagList(
        fluidRow(
          column(1), column(2, tags$b("Programme")), column(2, tags$b("Other")),
          column(1, tags$b("Year")), column(1, tags$b("Rooms")),
          column(1, tags$b("Wkshp")), column(1, tags$b("M")),
          column(1, tags$b("F")), column(1, tags$b("Tot")), column(1)
        ),
        rows
      )
    })

    # Live total per row
    observe({
      n <- enrolment_rows()
      lapply(seq_len(n), function(i) {
        local({
          ii <- i
          output[[paste0("enrol_tot_", ii)]] <- renderUI({
            m <- as.integer(input[[paste0("enrol_m_", ii)]]) %||% 0L
            f <- as.integer(input[[paste0("enrol_f_", ii)]]) %||% 0L
            strong(m + f)
          })
        })
      })
    })

    observeEvent(input$enrol_add_row, { enrolment_rows(enrolment_rows() + 1L) })

    # PWSN rows
    output$pwsn_rows_ui <- renderUI({
      n <- pwsn_rows()
      if (n == 0) return(p("No PWSN records entered.", class = "text-muted"))
      lapply(seq_len(n), function(i) {
        fluidRow(class = "pwsn-row",
          column(2, selectInput(ns(paste0("pwsn_prog_",  i)), "Programme",
                                choices = programme_choices, width="100%")),
          column(1, selectInput(ns(paste0("pwsn_yr_",   i)), "Year",
                                choices = c(1,2,3), width="100%")),
          column(3, selectInput(ns(paste0("pwsn_imp_",  i)), "Impairment Category",
                                choices = impairment_choices, width="100%")),
          column(2, numericInput(ns(paste0("pwsn_m_",   i)), "Male",   0, min=0, width="100%")),
          column(2, numericInput(ns(paste0("pwsn_f_",   i)), "Female", 0, min=0, width="100%")),
          column(2, uiOutput(ns(paste0("pwsn_err_", i))))
        )
      })
    })

    observeEvent(input$pwsn_add_row, { pwsn_rows(pwsn_rows() + 1L) })

    # WEL Summary rows
    output$wel_rows_ui <- renderUI({
      n <- wel_rows()
      lapply(seq_len(n), function(i) {
        fluidRow(class = "wel-row",
          column(2, selectInput(ns(paste0("wel_prog_", i)), "Programme",
                                choices = programme_choices, width="100%")),
          column(1, selectInput(ns(paste0("wel_yr_",   i)), "Year",
                                choices = c(1,2,3), width="100%")),
          column(2, numericInput(ns(paste0("wel_due_m_",    i)), "Due (M)",    0, min=0, width="100%")),
          column(2, numericInput(ns(paste0("wel_due_f_",    i)), "Due (F)",    0, min=0, width="100%")),
          column(2, numericInput(ns(paste0("wel_placed_m_", i)), "Placed (M)", 0, min=0, width="100%")),
          column(2, numericInput(ns(paste0("wel_placed_f_", i)), "Placed (F)", 0, min=0, width="100%")),
          column(1, uiOutput(ns(paste0("wel_err_", i))))
        )
      })
    })

    observeEvent(input$wel_add_row, { wel_rows(wel_rows() + 1L) })

    # Industry partner rows
    output$industry_rows_ui <- renderUI({
      n <- industry_rows()
      if (n == 0) return(p("No industry partners entered.", class = "text-muted"))
      lapply(seq_len(n), function(i) {
        fluidRow(class = "ind-row",
          column(3, textInput(  ns(paste0("ind_name_",   i)), "Industry Name",    width="100%")),
          column(2, selectInput(ns(paste0("ind_mou_",    i)), "Signed MoU/MoP",
                                choices = c("","Yes"="TRUE","No"="FALSE"), width="100%")),
          column(2, textInput(  ns(paste0("ind_status_", i)), "MoU Status",       width="100%")),
          column(2, selectInput(ns(paste0("ind_region_", i)), "Region",
                                choices = c("", region_choices),            width="100%")),
          column(3, textInput(  ns(paste0("ind_mobile_", i)), "Mobile Number",    width="100%"))
        )
      })
    })

    observeEvent(input$ind_add_row, { industry_rows(industry_rows() + 1L) })

    # Exam rows
    output$exam_rows_ui <- renderUI({
      n <- exam_rows()
      lapply(seq_len(n), function(i) {
        fluidRow(class = "exam-row",
          column(2, selectInput(ns(paste0("exam_prog_",    i)), "Programme",
                                choices = programme_choices,  width="100%")),
          column(2, textInput(  ns(paste0("exam_prog_ot_", i)), "Other programme",  width="100%")),
          column(2, selectInput(ns(paste0("exam_type_",    i)), "Exam Type",
                                choices = c("", exam_type_choices), width="100%")),
          column(1, numericInput(ns(paste0("exam_reg_m_",  i)), "Reg. M", 0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("exam_reg_f_",  i)), "Reg. F", 0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("exam_pres_m_", i)), "Pres. M",0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("exam_pres_f_", i)), "Pres. F",0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("exam_pass_m_", i)), "Pass. M",0, min=0, width="100%")),
          column(1, numericInput(ns(paste0("exam_pass_f_", i)), "Pass. F",0, min=0, width="100%")),
          column(0, uiOutput(ns(paste0("exam_err_", i))))
        )
      })
    })

    observeEvent(input$exam_add_row, { exam_rows(exam_rows() + 1L) })

    # Graduate rows
    output$grad_rows_ui <- renderUI({
      n <- grad_rows()
      lapply(seq_len(n), function(i) {
        fluidRow(class = "grad-row",
          column(3, textInput(  ns(paste0("grad_name_",    i)), "Full Name",     width="100%")),
          column(2, selectInput(ns(paste0("grad_prog_",    i)), "Programme",
                                choices = programme_choices,   width="100%")),
          column(2, textInput(  ns(paste0("grad_prog_ot_", i)), "Other programme", width="100%")),
          column(2, selectInput(ns(paste0("grad_exam_",    i)), "Exam Type",
                                choices = c("", exam_type_choices), width="100%")),
          column(1, numericInput(ns(paste0("grad_year_",   i)), "Year",
                                 value=as.integer(format(Sys.Date(),"%Y")), min=2000, width="100%")),
          column(2, textInput(  ns(paste0("grad_mobile_",  i)), "Mobile",        width="100%"))
        )
      })
    })

    observeEvent(input$grad_add_row, { grad_rows(grad_rows() + 1L) })

    # Challenge rows
    output$chal_rows_ui <- renderUI({
      n <- chal_rows()
      lapply(seq_len(n), function(i) {
        fluidRow(class = "chal-row",
          column(5, selectInput(ns(paste0("chal_type_",    i)), "Challenge Type",
                                choices = c("", challenge_choices), width="100%")),
          column(4, textInput(  ns(paste0("chal_other_",   i)), "Other (specify)", width="100%")),
          column(3, textInput(  ns(paste0("chal_remarks_", i)), "Remarks",         width="100%"))
        )
      })
    })

    observeEvent(input$chal_add_row, { chal_rows(chal_rows() + 1L) })

    # ---- Collect all form data into a list -------------------
    collect_form_data <- function() {
      list(
        biodata = list(
          reporting_semester   = as.integer(input$sel_semester),
          reporting_month      = input$bio_reporting_month,
          reporting_year       = as.integer(format(Sys.Date(), "%Y")),
          academic_year        = APP_CONFIG$current_ay,
          principal_name       = input$bio_principal_name,
          principal_mobile     = input$bio_principal_mobile,
          principal_email      = input$bio_principal_email,
          has_sickbay          = input$bio_has_sickbay   == "TRUE",
          has_library          = input$bio_has_library   == "TRUE",
          library_stocked      = input$bio_library_stocked == "TRUE",
          has_ict_lab          = input$bio_has_ict_lab   == "TRUE",
          ict_lab_equipped     = input$bio_ict_lab_equipped == "TRUE",
          day_enrolment_yr1    = as.integer(input$bio_day_enrolment),
          boarding_enrolment_yr1 = as.integer(input$bio_boarding_enrolment),
          fee_paying_enrolment = as.integer(input$bio_fee_paying),
          additional_remarks   = input$bio_remarks
        ),
        enrolment = lapply(seq_len(enrolment_rows()), function(i) {
          list(
            programme_id       = as.integer(input[[paste0("enrol_prog_", i)]]),
            programme_free     = input[[paste0("enrol_prog_ot_", i)]],
            year_of_study      = as.integer(input[[paste0("enrol_yr_", i)]]),
            num_classrooms     = as.integer(input[[paste0("enrol_cls_", i)]]),
            num_workshops      = as.integer(input[[paste0("enrol_wks_", i)]]),
            enrolment_male     = as.integer(input[[paste0("enrol_m_", i)]]) %||% 0L,
            enrolment_female   = as.integer(input[[paste0("enrol_f_", i)]]) %||% 0L
          )
        }),
        pwsn = lapply(seq_len(pwsn_rows()), function(i) {
          list(
            programme_id  = as.integer(input[[paste0("pwsn_prog_", i)]]),
            year_of_study = as.integer(input[[paste0("pwsn_yr_",   i)]]),
            impairment_id = as.integer(input[[paste0("pwsn_imp_",  i)]]),
            pwsn_male     = as.integer(input[[paste0("pwsn_m_",    i)]]) %||% 0L,
            pwsn_female   = as.integer(input[[paste0("pwsn_f_",    i)]]) %||% 0L
          )
        }),
        wel_summary = lapply(seq_len(wel_rows()), function(i) {
          list(
            programme_id    = as.integer(input[[paste0("wel_prog_",     i)]]),
            year_of_study   = as.integer(input[[paste0("wel_yr_",       i)]]),
            num_due_male    = as.integer(input[[paste0("wel_due_m_",    i)]]) %||% 0L,
            num_due_female  = as.integer(input[[paste0("wel_due_f_",    i)]]) %||% 0L,
            num_placed_male = as.integer(input[[paste0("wel_placed_m_", i)]]) %||% 0L,
            num_placed_female = as.integer(input[[paste0("wel_placed_f_", i)]]) %||% 0L
          )
        }),
        exam = lapply(seq_len(exam_rows()), function(i) {
          list(
            exam_year      = as.integer(input$exam_year),
            exam_month     = input$exam_month,
            programme_id   = as.integer(input[[paste0("exam_prog_", i)]]),
            prog_free      = input[[paste0("exam_prog_ot_", i)]],
            exam_type_id   = as.integer(input[[paste0("exam_type_", i)]]),
            registered_male  = as.integer(input[[paste0("exam_reg_m_",  i)]]) %||% 0L,
            registered_female= as.integer(input[[paste0("exam_reg_f_",  i)]]) %||% 0L,
            present_male     = as.integer(input[[paste0("exam_pres_m_", i)]]) %||% 0L,
            present_female   = as.integer(input[[paste0("exam_pres_f_", i)]]) %||% 0L,
            passed_male      = as.integer(input[[paste0("exam_pass_m_", i)]]) %||% 0L,
            passed_female    = as.integer(input[[paste0("exam_pass_f_", i)]]) %||% 0L
          )
        }),
        graduates = lapply(seq_len(grad_rows()), function(i) {
          list(
            full_name      = input[[paste0("grad_name_",    i)]],
            programme_id   = as.integer(input[[paste0("grad_prog_",    i)]]),
            prog_free      = input[[paste0("grad_prog_ot_", i)]],
            exam_type_id   = as.integer(input[[paste0("grad_exam_",    i)]]),
            graduating_year= as.integer(input[[paste0("grad_year_",    i)]]),
            contact_mobile = input[[paste0("grad_mobile_",  i)]]
          )
        }),
        challenges = lapply(seq_len(chal_rows()), function(i) {
          list(
            challenge_id        = as.integer(input[[paste0("chal_type_",    i)]]),
            challenge_free_text = input[[paste0("chal_other_",   i)]],
            remarks             = input[[paste0("chal_remarks_", i)]]
          )
        }),
        recommendations = input$recommendations_text
      )
    }

    # ---- Validate -------------------------------------------
    run_validation <- function(data) {
      errors <- character(0)

      # Enrolment cross-checks
      for (row in data$enrolment) {
        errs <- validate_enrolment_row(
          row$enrolment_male, row$enrolment_female, 0, 0)
        errors <- c(errors, errs)
      }

      # PWSN cross-check against enrolment totals
      enrol_totals <- vapply(data$enrolment, function(r) {
        r$enrolment_male + r$enrolment_female
      }, integer(1))
      for (pw in data$pwsn) {
        errs <- validate_enrolment_row(
          pw$pwsn_male, pw$pwsn_female, pw$pwsn_male, pw$pwsn_female)
        errors <- c(errors, errs)
      }

      # WEL cross-check
      for (w in data$wel_summary) {
        errs <- validate_wel_summary(
          w$num_due_male, w$num_due_female,
          w$num_placed_male, w$num_placed_female)
        errors <- c(errors, errs)
      }

      # Exam cross-check
      for (ex in data$exam) {
        errs <- validate_exam_row(
          ex$registered_male, ex$registered_female,
          ex$present_male,    ex$present_female,
          ex$passed_male,     ex$passed_female)
        errors <- c(errors, errs)
      }

      unique(errors)
    }

    # ---- Save draft -----------------------------------------
    observeEvent(input$btn_save_draft, {
      req(auth$logged_in, auth$institution_id)
      data   <- collect_form_data()
      errors <- run_validation(data)

      if (length(errors) > 0) {
        output$validation_messages <- renderUI({
          div(class = "alert alert-warning",
              h5(icon("exclamation-triangle"), " Please fix the following:"),
              tags$ul(lapply(errors, tags$li)))
        })
        return()
      }

      withProgress(message = "Saving draft...", {
        sub_id <- save_m1_draft(pool, auth, data, current_submission())
        if (!is.na(sub_id)) {
          current_submission(list(submission_id = sub_id,
                                  status  = "Draft",
                                  version = 1))
          output$save_feedback <- renderUI(
            div(class = "alert alert-success",
                icon("check"), " Draft saved successfully."))
          output$validation_messages <- renderUI(NULL)
          log_action(pool, auth$user_id, "M1_SAVE_DRAFT",
                     "submissions", sub_id)
        } else {
          output$save_feedback <- renderUI(
            div(class = "alert alert-danger",
                icon("times"), " Save failed. Please try again."))
        }
      })
    })

    # ---- Submit for review -----------------------------------
    observeEvent(input$btn_submit, {
      req(auth$logged_in, auth$institution_id)
      data   <- collect_form_data()
      errors <- run_validation(data)

      # Extra check: window must be open
      if (!is_window_open(pool, "M1", APP_CONFIG$current_ay,
                          as.integer(input$sel_semester))) {
        errors <- c(errors,
          "The submission window for M1 is not currently open. Contact your regional officer.")
      }

      if (length(errors) > 0) {
        output$validation_messages <- renderUI({
          div(class = "alert alert-danger",
              h5(icon("times-circle"), " Cannot submit — please fix:"),
              tags$ul(lapply(errors, tags$li)))
        })
        return()
      }

      withProgress(message = "Submitting...", {
        sub_id <- save_m1_draft(pool, auth, data, current_submission())
        if (!is.na(sub_id)) {
          # Mark as Submitted
          db_execute(pool,
            "UPDATE submissions SET status='Submitted', submitted_by=$1, submitted_at=NOW()
             WHERE submission_id=$2",
            list(auth$user_id, sub_id))
          current_submission(list(submission_id=sub_id, status="Submitted", version=1))
          output$save_feedback <- renderUI(
            div(class = "alert alert-success",
                icon("check-circle"),
                " Submitted successfully. Your regional officer will be notified."))
          output$validation_messages <- renderUI(NULL)
          log_action(pool, auth$user_id, "M1_SUBMIT",
                     "submissions", sub_id)
        }
      })
    })

    # ---- Helper: persist all M1 data to DB ------------------
    save_m1_draft <- function(pool, auth, data, existing_sub) {
      tryCatch({
        con <- pool::poolCheckout(pool)
        on.exit(pool::poolReturn(con))

        DBI::dbBegin(con)

        # 1. Upsert submission record
        if (is.null(existing_sub)) {
          sub_id <- DBI::dbGetQuery(con,
            "INSERT INTO submissions
               (institution_id, module_code, academic_year, semester, status)
             VALUES ($1,'M1',$2,$3,'Draft')
             RETURNING submission_id",
            params = list(auth$institution_id,
                          APP_CONFIG$current_ay,
                          data$biodata$reporting_semester))[[1]]
        } else {
          sub_id <- existing_sub$submission_id
          DBI::dbExecute(con,
            "UPDATE submissions SET updated_at=NOW() WHERE submission_id=$1",
            params = list(sub_id))
        }

        # 2. Upsert biodata
        DBI::dbExecute(con,
          "INSERT INTO m1_biodata
             (submission_id, reporting_semester, reporting_month, reporting_year,
              academic_year, principal_name, principal_mobile, principal_email,
              has_sickbay, has_library, library_stocked, has_ict_lab,
              ict_lab_equipped, day_enrolment_yr1, boarding_enrolment_yr1,
              fee_paying_enrolment, additional_remarks)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
           ON CONFLICT (submission_id) DO UPDATE SET
             reporting_semester=EXCLUDED.reporting_semester,
             reporting_month=EXCLUDED.reporting_month,
             reporting_year=EXCLUDED.reporting_year,
             principal_name=EXCLUDED.principal_name,
             principal_mobile=EXCLUDED.principal_mobile,
             principal_email=EXCLUDED.principal_email,
             has_sickbay=EXCLUDED.has_sickbay,
             has_library=EXCLUDED.has_library,
             library_stocked=EXCLUDED.library_stocked,
             has_ict_lab=EXCLUDED.has_ict_lab,
             ict_lab_equipped=EXCLUDED.ict_lab_equipped,
             day_enrolment_yr1=EXCLUDED.day_enrolment_yr1,
             boarding_enrolment_yr1=EXCLUDED.boarding_enrolment_yr1,
             fee_paying_enrolment=EXCLUDED.fee_paying_enrolment,
             additional_remarks=EXCLUDED.additional_remarks,
             updated_at=NOW()",
          params = list(
            sub_id,
            data$biodata$reporting_semester,
            data$biodata$reporting_month,
            data$biodata$reporting_year,
            data$biodata$academic_year,
            data$biodata$principal_name,
            data$biodata$principal_mobile,
            data$biodata$principal_email,
            data$biodata$has_sickbay,
            data$biodata$has_library,
            data$biodata$library_stocked,
            data$biodata$has_ict_lab,
            data$biodata$ict_lab_equipped,
            data$biodata$day_enrolment_yr1,
            data$biodata$boarding_enrolment_yr1,
            data$biodata$fee_paying_enrolment,
            data$biodata$additional_remarks
          ))

        # 3. Delete and re-insert child rows (simpler than upsert for dynamic tables)
        DBI::dbExecute(con, "DELETE FROM m1_enrolment WHERE submission_id=$1", list(sub_id))
        for (row in data$enrolment) {
          if (row$enrolment_male + row$enrolment_female > 0 || !is.null(row$programme_id)) {
            DBI::dbExecute(con,
              "INSERT INTO m1_enrolment
                 (submission_id,programme_id,programme_free_text,year_of_study,
                  num_classrooms,num_workshops,enrolment_male,enrolment_female)
               VALUES ($1,$2,$3,$4,$5,$6,$7,$8)",
              params = list(sub_id,
                if (row$programme_id == 0) NA_integer_ else row$programme_id,
                row$programme_free,
                row$year_of_study,
                row$num_classrooms, row$num_workshops,
                row$enrolment_male, row$enrolment_female))
          }
        }

        DBI::dbExecute(con, "DELETE FROM m1_pwsn WHERE submission_id=$1", list(sub_id))
        for (row in data$pwsn) {
          if (row$pwsn_male + row$pwsn_female > 0) {
            DBI::dbExecute(con,
              "INSERT INTO m1_pwsn (submission_id,programme_id,year_of_study,impairment_id,pwsn_male,pwsn_female)
               VALUES ($1,$2,$3,$4,$5,$6)",
              params = list(sub_id, row$programme_id, row$year_of_study,
                            row$impairment_id, row$pwsn_male, row$pwsn_female))
          }
        }

        DBI::dbExecute(con, "DELETE FROM m1_wel_summary WHERE submission_id=$1", list(sub_id))
        for (row in data$wel_summary) {
          if (row$num_due_male + row$num_due_female > 0) {
            DBI::dbExecute(con,
              "INSERT INTO m1_wel_summary
                 (submission_id,programme_id,year_of_study,
                  num_due_male,num_due_female,num_placed_male,num_placed_female)
               VALUES ($1,$2,$3,$4,$5,$6,$7)",
              params = list(sub_id, row$programme_id, row$year_of_study,
                            row$num_due_male, row$num_due_female,
                            row$num_placed_male, row$num_placed_female))
          }
        }

        DBI::dbExecute(con, "DELETE FROM m1_exam WHERE submission_id=$1", list(sub_id))
        for (row in data$exam) {
          if (!is.na(row$exam_type_id) && row$exam_type_id > 0) {
            DBI::dbExecute(con,
              "INSERT INTO m1_exam
                 (submission_id,exam_year,exam_month,programme_id,programme_free_text,
                  exam_type_id,registered_male,registered_female,
                  present_male,present_female,passed_male,passed_female)
               VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",
              params = list(sub_id, row$exam_year, row$exam_month,
                if (row$programme_id == 0) NA_integer_ else row$programme_id,
                row$prog_free, row$exam_type_id,
                row$registered_male, row$registered_female,
                row$present_male, row$present_female,
                row$passed_male, row$passed_female))
          }
        }

        DBI::dbExecute(con, "DELETE FROM m1_graduates WHERE submission_id=$1", list(sub_id))
        for (row in data$graduates) {
          if (nchar(trimws(row$full_name %||% "")) > 0) {
            DBI::dbExecute(con,
              "INSERT INTO m1_graduates
                 (submission_id,full_name,programme_id,programme_free_text,
                  exam_type_id,graduating_year,contact_mobile)
               VALUES ($1,$2,$3,$4,$5,$6,$7)",
              params = list(sub_id, row$full_name,
                if (row$programme_id == 0) NA_integer_ else row$programme_id,
                row$prog_free, row$exam_type_id,
                row$graduating_year, row$contact_mobile))
          }
        }

        DBI::dbExecute(con, "DELETE FROM m1_challenges WHERE submission_id=$1", list(sub_id))
        for (row in data$challenges) {
          if (!is.na(row$challenge_id) && row$challenge_id > 0) {
            DBI::dbExecute(con,
              "INSERT INTO m1_challenges (submission_id,challenge_id,challenge_free_text,remarks)
               VALUES ($1,$2,$3,$4)",
              params = list(sub_id, row$challenge_id,
                            row$challenge_free_text, row$remarks))
          }
        }

        DBI::dbExecute(con, "DELETE FROM m1_recommendations WHERE submission_id=$1", list(sub_id))
        recs <- strsplit(data$recommendations %||% "", "\n")[[1]]
        recs <- recs[nchar(trimws(recs)) > 0]
        for (rec in recs) {
          DBI::dbExecute(con,
            "INSERT INTO m1_recommendations (submission_id, recommendation_text) VALUES ($1,$2)",
            params = list(sub_id, trimws(rec)))
        }

        DBI::dbCommit(con)
        sub_id

      }, error = function(e) {
        tryCatch(DBI::dbRollback(con), error = function(e2) NULL)
        message("[save_m1_draft] ERROR: ", conditionMessage(e))
        NA_integer_
      })
    }

    # ---- Load existing submission data ----------------------
    load_submission_data <- function(sub_id) {
      # Load biodata
      bd <- db_query(pool,
        "SELECT * FROM m1_biodata WHERE submission_id=$1", list(sub_id))
      if (nrow(bd) > 0) {
        updateSelectInput(session, "sel_semester",
                          selected = as.character(bd$reporting_semester[1]))
        updateSelectInput(session, "bio_reporting_month",
                          selected = bd$reporting_month[1])
        updateTextInput(session, "bio_principal_name",  value = bd$principal_name[1] %||% "")
        updateTextInput(session, "bio_principal_mobile",value = bd$principal_mobile[1] %||% "")
        updateTextInput(session, "bio_principal_email", value = bd$principal_email[1] %||% "")
        updateNumericInput(session, "bio_day_enrolment",     value = bd$day_enrolment_yr1[1] %||% 0)
        updateNumericInput(session, "bio_boarding_enrolment",value = bd$boarding_enrolment_yr1[1] %||% 0)
        updateNumericInput(session, "bio_fee_paying",        value = bd$fee_paying_enrolment[1] %||% 0)
        updateTextAreaInput(session, "bio_remarks",          value = bd$additional_remarks[1] %||% "")
        if (!is.na(bd$has_sickbay[1]))
          updateSelectInput(session, "bio_has_sickbay", selected = as.character(bd$has_sickbay[1]))
        if (!is.na(bd$has_library[1]))
          updateSelectInput(session, "bio_has_library", selected = as.character(bd$has_library[1]))
      }

      # Load enrolment
      en <- db_query(pool,
        "SELECT * FROM m1_enrolment WHERE submission_id=$1 ORDER BY enrolment_id", list(sub_id))
      if (nrow(en) > 0) {
        enrolment_rows(nrow(en))
        # Individual fields updated on next render cycle; handled by Shiny's reactive re-render
      }
    }

  })  # moduleServer
}
