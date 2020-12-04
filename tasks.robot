# ## Web store order robot example
# This example is explained in detail <a href="https://robocorp.com/docs/development-howtos/browser/web-store-order-robot">here</a>.
#
# > !! **To run this code locally, you need to complete additional setup steps. Check the README.md file or the <a href="https://robocorp.com/docs/development-howtos/browser/web-store-order-robot">example page</a> for details!**
#

*** Settings ***
Documentation     Swag order robot. Places orders at https://www.saucedemo.com/
...               by processing a spreadsheet of orders and ordering the
...               specified products using browser automation. Uses local or
...               cloud vault for credentials.
Library           OperatingSystem
Library           Orders
Library           Browser
Library           RPA.HTTP
Library           RPA.Robocloud.Secrets

*** Variables ***
${EXCEL_FILE_NAME}=    Data.xlsx
${EXCEL_FILE_URL}=    https://github.com/robocorp/example-activities/raw/master/web-store-order-processor/devdata/${EXCEL_FILE_NAME}
${SWAG_LABS_URL}=    https://www.saucedemo.com

*** Keywords ***
Process orders
    Open Swag Labs
    ${secret}=    Get Secret    swaglabs
    Login    ${secret}[username]    ${secret}[password]
    ${orders}=    Collect orders
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure    Process order    ${order}
    END
    [Teardown]    Close Browser

*** Keywords ***
Submit Form
    Click  input[type=submit]

*** Keywords ***
Open Swag Labs
    New Browser  headless=False
    New Page  ${SWAG_LABS_URL}

*** Keywords ***
Login
    [Arguments]    ${user_name}    ${password}
    Fill Text    id=user-name    ${user_name}
    Fill Secret  id=password    ${password}
    Submit Form
    Assert logged in

*** Keywords ***
Assert logged in
    Wait For Elements State    inventory_container
    Get Url  ==    ${SWAG_LABS_URL}/inventory.html

*** Keywords ***
Collect orders
    RPA.HTTP.Download    ${EXCEL_FILE_URL}    overwrite=True
    ${orders}=    Get Orders    ${EXCEL_FILE_NAME}
    [Return]    ${orders}

*** Keywords ***
Process order
    [Arguments]    ${order}
    Reset application state
    Open products page
    Assert cart is empty
    Add product to cart    ${order}
    Open cart
    Assert one product in cart    ${order}
    Checkout    ${order}
    Open products page

*** Keywords ***
Reset application state
    Click  css=.bm-burger-button button
    Click    id=reset_sidebar_link

*** Keywords ***
Open products page
    Go To    ${SWAG_LABS_URL}/inventory.html

*** Keywords ***
Assert cart is empty
    Get Text  css=.shopping_cart_link    ==  ${EMPTY}
    Get Element State    css=.shopping_cart_badge  visible  ==  False

*** Keywords ***
Add product to cart
    [Arguments]    ${order}
    ${product_name}=    Set Variable    ${order["item"]}
    ${locator}=    Set Variable    xpath=//div[@class="inventory_item" and descendant::div[contains(text(), "${product_name}")]]
    ${add_to_cart_button}=    Get Element  ${locator} >> .btn_primary
    Click  ${add_to_cart_button}
    Assert items in cart    1

*** Keywords ***
Assert items in cart
    [Arguments]    ${quantity}
    Get Text    css=.shopping_cart_badge    ==  ${quantity}

*** Keywords ***
Open cart
    Click    css=.shopping_cart_link
    Assert cart page

*** Keywords ***
Assert cart page
    Wait For Elements State    id=cart_contents_container
    Get Url  ==   ${SWAG_LABS_URL}/cart.html

*** Keywords ***
Assert one product in cart
    [Arguments]    ${order}
    Get Text    css=.cart_quantity    ==  1
    Get Text    css=.inventory_item_name    ==  ${order["item"]}

*** Keywords ***
Checkout
    [Arguments]    ${order}
    Click    css=.checkout_button
    Fill Text    id=first-name    ${order["first_name"]}
    Fill Text    id=last-name    ${order["last_name"]}
    Fill Text    id=postal-code    ${{ str(${order["zip"]} )}}
    Submit Form
    Click  css=.btn_action

*** Keywords ***
Assert checkout information page
    Wait For Elements State    id=checkout_info_container
    Get Url  ==  ${SWAG_LABS_URL}/checkout-step-one.html

*** Keywords ***
Assert checkout confirmation page
    Wait For Elements State    id=checkout_summary_container
    Get Url  ==  ${SWAG_LABS_URL}/checkout-step-two.html

*** Keywords ***
Assert checkout complete page
    Wait For Elements State    id=checkout_complete_container
    Get Url  ==  ${SWAG_LABS_URL}/checkout-complete.html

*** Tasks ***
Place orders
    Process orders
