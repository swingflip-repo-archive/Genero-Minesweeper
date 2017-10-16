################################################################################
#APPLICATION MAIN
#Written by Ryan Hamlin - 2017. (Ryan@ryanhamlin.co.uk)
#
#The main bulk of the application is located here with the demos and tools
#broken in to seperate modules to make things easier to manage...
################################################################################
IMPORT os
IMPORT util
GLOBALS "globals.4gl"

    DEFINE #These are very useful module variables to have defined!
        TERMINATE SMALLINT,
        m_string_tokenizer base.StringTokenizer,
        m_window ui.Window,
        m_form ui.Form,
        m_dom_node1 om.DomNode,
        m_index INTEGER,
        m_ok SMALLINT,
        m_status STRING
        
    DEFINE
        m_username STRING,
        m_password STRING,
        m_remember STRING,
        m_image STRING
    
FUNCTION initialise_app()
    #******************************************************************************#
    #Grab deployment data...
        CALL ui.interface.getFrontEndName() RETURNING global.g_info.deployment_type
        CALL ui.interface.frontCall("standard", "feInfo", "osType", global.g_info.os_type)
        CALL ui.Interface.frontCall("standard", "feInfo", "ip", global.g_info.ip)
        CALL ui.Interface.frontCall("standard", "feInfo", "deviceId", global.g_info.device_name)    
        CALL ui.Interface.frontCall("standard", "feInfo", "screenResolution", global.g_info.resolution)

    #******************************************************************************#
    #Set global application details here...

        LET global.g_application_title =%"main.string.App_Title"
        LET global.g_application_version =%"main.string.App_Version"
        LET global.g_title =  global.g_application_title || " " || global.g_application_version
        
    #******************************************************************************#

        # RUN "set > /tmp/mobile.env" # Dump the environment for debugging.
        #BREAKPOINT #Uncomment to step through application
        DISPLAY "\nStarting up " || global.g_application_title || " " || global.g_application_version || "...\n"

        #Uncomment the below to display device data when running.
        
        IF global.g_info.deployment_type <> "GMA" AND global.g_info.deployment_type <> "GMI"
        THEN
            {DISPLAY "--Deployment Data--\n" ||
                    "Deployment Type: " || global.g_info.deployment_type || "\n" ||
                    "OS Type: " || global.g_info.os_type || "\n" ||
                    "User Locale: " || global.g_info.locale || "\n" ||
                    "Device IP: " || global.g_info.ip || "\n" ||
                    "Resolution: " || global.g_info.resolution || "\n" ||
                    "-------------------\n"}
        ELSE
            {DISPLAY "--Deployment Data--\n" ||
                    "Deployment Type: " || global.g_info.deployment_type || "\n" ||
                    "OS Type: " || global.g_info.os_type || "\n" ||
                    "User Locale: " || global.g_info.locale || "\n" ||
                    "Device IP: " || global.g_info.ip || "\n" ||
                    "Device ID: " || global.g_info.device_name || "\n" ||
                    "Resolution: " || global.g_info.resolution || "\n" ||
                    "-------------------\n"}
        END IF
        
        LET m_string_tokenizer = base.StringTokenizer.create(global.g_info.resolution,"x")

        WHILE m_string_tokenizer.hasMoreTokens()
            IF m_index = 1
            THEN
                LET global.g_info.resolution_x = m_string_tokenizer.nextToken() || "px"
            ELSE
                LET global.g_info.resolution_y = m_string_tokenizer.nextToken() || "px"
            END IF
            LET m_index = m_index + 1
        END WHILE

    #******************************************************************************#
    # HERE IS WHERE YOU CONFIGURE GOBAL SWITCHES FOR THE APPLICATION
    # ADJUST THESE AS YOU SEEM FIT. BELOW IS A LIST OF OPTIONS IN ORDER:
    #        global_config.g_application_database_ver INTEGER,               #Application Database Version (This is useful to force database additions to pre-existing db instances)
    #        global_config.g_enable_splash SMALLINT,                         #Open splashscreen when opening the application.
    #        global_config.g_splash_duration INTEGER,                        #Splashscreen duration (seconds) global_config.g_enable_splash needs to be enabled!
    #        global_config.g_enable_login SMALLINT                           #Boot in to login menu or straight into application (open_application())
    #        global_config.g_splash_width STRING,                            #Login menu splash width when not in mobile
    #        global_config.g_splash_height STRING,                           #Login menu splash height when not in mobile
    #        global_config.g_enable_geolocation SMALLINT,                    #Toggle to enable geolocation
    #        global_config.g_enable_mobile_title SMALLINT,                   #Toggle application title on mobile
    #        global_config.g_local_stat_limit INTEGER,                       #Number of max local stat records before pruning
    #        global.g_online_pinglobal_config.g_URL STRING,                         #URL of public site to test internet connectivity (i.e. http://www.google.com) 
    #        global_config.g_enable_timed_connect SMALLINT,                  #Enable timed connectivity checks
    #        global_config.g_timed_checks_time INTEGER                       #Time in seconds before checking connectivity (global_config.g_enable_timed_connect has to be enabled)
    #        global_config.g_date_format STRING                              #Datetime format. i.e.  "%d/%m/%Y %H:%M"
    #        global_config.g_image_dest STRING                               #Webserver destination for image payloads. i.e. "Webservice_1" (Not used as of yet)
    #        global_config.g_ws_end_point STRING,                            #The webservice end point. 
    #        global_config.g_enable_timed_image_upload SMALLINT,             #Enable timed image queue uploads (Could have a performance impact!)
    #        global_config.g_local_images_available DYNAMIC ARRAY OF CHAR(2) #Available localisations for images.
    #        global_config.g_default_language STRING,                        #The default language used within the application (i.e. EN)
    # Here are globals not included in initialize_globals function due to sheer size of the arguement data...

       CALL sync_config("GGAT.config",FALSE)
			 CALL sync_assets(".mp3",FALSE)
       CALL initialize_globals()
          RETURNING m_ok
          
        IF m_ok = FALSE
        THEN
             CALL fgl_winmessage(global.g_title, %"main.string.ERROR_1001", "stop")
             EXIT PROGRAM 1001
        END IF

        IF global_config.g_enable_geolocation = TRUE
        THEN
            IF global.g_info.deployment_type <> "GMA" AND global.g_info.deployment_type <> "GMI"
            THEN
                DISPLAY "****************************************************************************************\n" ||
                        "WARNING: Set up error, track geolocation is enabled and you are not deploying in mobile.\n" ||
                        "****************************************************************************************\n"
            ELSE
                CALL ui.Interface.frontCall("mobile", "getGeolocation", [], [global.g_info.geo_status, global.g_info.geo_lat, global.g_info.geo_lon])
                DISPLAY "--Geolocation Tracking Enabled!--"
                DISPLAY "Geolocation Tracking Status: " || global.g_info.geo_status
                IF global.g_info.geo_status = "ok"
                THEN
                    DISPLAY "Latitude: " || global.g_info.geo_lat
                    DISPLAY "Longitude: " || global.g_info.geo_lon
                END IF
                DISPLAY "---------------------------------\n"
            END IF
        END IF

        CALL test_connectivity(global.g_info.deployment_type)
        CALL capture_local_stats(global.g_info.*)
            RETURNING m_ok

        CLOSE WINDOW SCREEN #Just incase
        
    #We are now initialised, we now just need to run each individual window functions...

        IF global_config.g_enable_splash = TRUE AND global_config.g_splash_duration > 0
        THEN
            CALL run_splash_screen()
        ELSE
            IF global_config.g_enable_login = TRUE
            THEN
                CALL login_screen() 
            ELSE
                CALL open_application()
            END IF
        END IF
    
END FUNCTION

################################################################################

################################################################################
#Individual window/form functions...
################################################################################

FUNCTION run_splash_screen() #Application Splashscreen window function

    DEFINE
        f_result STRING
        
    IF global.g_info.deployment_type = "GDC"
    THEN
        OPEN WINDOW w WITH FORM "splash_screen"
    ELSE
        OPEN WINDOW w WITH FORM "splash_screen"
    END IF

    INITIALIZE f_result TO NULL
    TRY 
        CALL ui.Interface.frontCall("webcomponent","call",["formonly.splashwc","setLocale",global.g_language_short],[f_result])
    CATCH
        ERROR err_get(status)
        DISPLAY err_get(status)
    END TRY
    
    LET TERMINATE = FALSE
    INITIALIZE global.g_instruction TO NULL
    LET m_window = ui.Window.getCurrent()

    IF global.g_info.deployment_type <> "GMA" AND global.g_info.deployment_type <> "GMI"
    THEN
        CALL m_window.setText(global.g_title)
    ELSE
        IF global_config.g_enable_mobile_title = FALSE
        THEN
            CALL m_window.setText("")
        ELSE
            CALL m_window.setText(global.g_title)
        END IF
    END IF

    LET TERMINATE = FALSE

    WHILE TERMINATE = FALSE
        MENU

        ON TIMER global_config.g_splash_duration
            LET TERMINATE = TRUE
            EXIT MENU

        BEFORE MENU
            CALL DIALOG.setActionHidden("close",1)

        ON ACTION CLOSE
            LET TERMINATE = TRUE
            EXIT MENU
              
        END MENU
    END WHILE

    IF global_config.g_enable_login = TRUE
    THEN
        CLOSE WINDOW w
        CALL login_screen() 
    ELSE
        CLOSE WINDOW w
        CALL open_application()
    END IF

END FUNCTION
#
#
#
#
FUNCTION login_screen() #Local Login window function

    #Stub, we don't need a login for minesweeper...
    
END FUNCTION
#
#
#
#
FUNCTION open_application() #First Application window function

    DEFINE
        f_level STRING,
        f_result STRING
        
    IF global.g_info.deployment_type = "GDC"
    THEN
        OPEN WINDOW w WITH FORM "wc_minesweeper"
				LET m_window = ui.Window.getCurrent()
				LET m_form = m_window.getForm()
				CALL m_form.loadToolBar("gdc_toolbar")
    ELSE
        OPEN WINDOW w WITH FORM "wc_minesweeper"
    END IF

    LET TERMINATE = FALSE
    INITIALIZE global.g_instruction TO NULL
    LET m_window = ui.Window.getCurrent()

    IF global.g_info.deployment_type <> "GMA" AND global.g_info.deployment_type <> "GMI"
    THEN
        CALL m_window.setText(global.g_title)
    ELSE
        IF global_config.g_enable_mobile_title = FALSE
        THEN
            CALL m_window.setText("")
        ELSE
            CALL m_window.setText(global.g_title)
        END IF
    END IF

    LET TERMINATE = FALSE

    WHILE TERMINATE = FALSE
        MENU
        
            ON TIMER global_config.g_timed_checks_time
                CALL connection_test()
                
            BEFORE MENU
                CALL connection_test()

            ON ACTION CLOSE
                LET global.g_instruction = "go_back"
                LET TERMINATE = TRUE
                EXIT MENU  

            ON ACTION bt_new_game
                OPEN WINDOW w2 WITH FORM "wc_minesweeper_select" ATTRIBUTES(TEXT="Select your difficulty...")
                INPUT f_level FROM level ATTRIBUTES(UNBUFFERED)

                    BEFORE INPUT
                        CALL DIALOG.setActionHidden("cancel",1)

                    ON ACTION ACCEPT
                        ACCEPT INPUT
                    ON ACTION CANCEL
                        #Do Nothing
                          
                    AFTER INPUT
                        END INPUT
                        CLOSE WINDOW w2
                        INITIALIZE f_result TO NULL
                        TRY 
                            CALL ui.Interface.frontCall("webcomponent","call",["formonly.sweeperwc","new_game",f_level],[f_result])
                        CATCH
                            ERROR err_get(status)
                            DISPLAY err_get(status)
                        END TRY

            ON ACTION gamewinner
								CALL ui.Interface.frontCall("standard", "playSound", [os.path.join(os.path.pwd(),os.path.join("resources","tada.mp3"))], [])
                CALL fgl_winmessage("Congratulations!", "YOU WIN!", "informaion")
            ON ACTION gameover
								CALL ui.Interface.frontCall("standard", "playSound", [os.path.join(os.path.pwd(),os.path.join("resources","explosion.mp3"))], [])
                CALL fgl_winmessage("Uh Oh!", "Game Over!", "informaion")           
              
        END MENU
    END WHILE

    CASE global.g_instruction #Depending on the instruction, we load up new windows/forms within the application whithout unloading.
        WHEN "go_back"
            CALL ui.Interface.refresh()
            CALL close_app()
        WHEN "logout"
            INITIALIZE global.g_user TO NULL
            INITIALIZE global.g_logged_in TO NULL
            DISPLAY "Logged out successfully!"
            CLOSE WINDOW w
            CALL login_screen()
        OTHERWISE
            CALL ui.Interface.refresh()
            CALL close_app()
    END CASE

END FUNCTION

################################################################################
#Module Functions...
################################################################################

FUNCTION connection_test() #Test online connectivity, call this whenever opening new window!
    IF global_config.g_enable_timed_connect = TRUE
    THEN
        CALL test_connectivity(global.g_info.deployment_type)
        IF global.g_online = "NONE" AND global.g_info.deployment_type = "GMA" OR global.g_online = "NONE" AND global.g_info.deployment_type = "GMI"
        THEN
            IF global_config.g_enable_mobile_title = FALSE
            THEN
                CALL m_window.setText(%"main.string.Working_Offline")
            ELSE
                CALL m_window.setText(%"main.string.Working_Offline" || global.g_title)
            END IF
        ELSE
            IF global_config.g_enable_mobile_title = FALSE
            THEN
                CALL m_window.setText("")
            ELSE
                CALL m_window.setText(global.g_title)
            END IF
        END IF
    END IF
END FUNCTION