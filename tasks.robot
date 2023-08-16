*** Settings ***
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Desktop
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           OperatingSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Get orders
    Fill orders
    Create ZIP package from PDF files   ${OUTPUT_DIR}${/}receipt    ${OUTPUT_DIR}${/}orders.zip
    Cleanup temporary directories


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order   browser_selection=Chrome

Get orders
    [Arguments]    ${url}=https://robotsparebinindustries.com/orders.csv
    Download    ${url}   overwrite=True   target_file=output/orders.csv
    ${orders}=    Read table from CSV   output/orders.csv
    RETURN   ${orders}


Fill orders
    ${orders}=    Get orders
    FOR   ${order}    IN    @{orders}
        Fill and submit the form for one robot    ${order}
    END
    

Close the annoying modal
    Click Button When Visible   xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill and submit the form for one robot
    [Arguments]    ${order}
    # using xpath to find the elements
    Select From List By Value   xpath://*[@id="head"]   ${order}[Head]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input   ${order}[Legs]    
    Input Text   xpath://*[@id="address"]   ${order}[Address]
    Select Radio Button    body   id-body-${order}[Body]
    # preview
    Click Button When Visible   id:preview
    Click Button When Visible   id:order
    # Wait for either success or error
    # success: id:order-another
    # error: @class:'alert alert-danger'
    Wait Until Element Is Visible    xpath://*[@id='order-another' or @class='alert alert-danger']    timeout=5s
    ${status} =    Run Keyword And Return Status    Page Should Contain Element    id:order-another
    IF    ${status}
        # success
        ${screenshot_file}=   Take a screenshot of the robot  ${order}[Order number]
        ${receipt_file}=   Store the receipt as a PDF file    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot_file}    ${receipt_file}    
        Click Button When Visible   id:order-another
        Close the annoying modal
    ELSE
        Fill and submit the form for one robot    ${order}
    END

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}images${/}order_preview_${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}images${/}order_preview_${order_number}.png

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${robot_order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${robot_order_receipt}    ${OUTPUT_DIR}${/}receipt${/}order_receipt_${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipt${/}order_receipt_${order_number}.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    # Embed the screenshot image into the PDF
    Add Watermark Image To Pdf    image_path=${screenshot}    output_path=${pdf}    source_path=${pdf}    coverage=0.2

Create ZIP package from PDF files
    [Arguments]    ${pdf_receipts_dir}=${OUTPUT_DIR}${/}receipt   ${zip_file_name}=${OUTPUT_DIR}${/}orders.zip
    Archive Folder With Zip
    ...    ${pdf_receipts_dir}
    ...    ${zip_file_name}

Cleanup temporary directories
    Remove Directory    ${OUTPUT_DIR}${/}images    True
    Remove Directory   ${OUTPUT_DIR}${/}receipt    True