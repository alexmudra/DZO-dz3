*** Settings ***
Library  Selenium2Library
Library  String
Library  DateTime
Library  dzo_service.py
Library  Collections

*** Variables ***
#${locator.assetId}  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span

*** Keywords ***
Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=   adapt_data_for_role   ${role_name}   ${tender_data}
  Log Many   ${tender_data}
  [Return]  ${tender_data}


Підготувати клієнт для користувача
  [Arguments]  ${username}
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
    Run Keyword If  '${USERS.users['${username}'].browser}' in 'Chrome chrome'  Run Keywords
    ...  Call Method  ${chrome_options}  add_argument  --headless
    ...  AND  Create Webdriver  Chrome  alias=my_alias  chrome_options=${chrome_options}
    ...  AND  Go To  ${USERS.users['${username}'].homepage}
    ...  ELSE  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=my_alias
    Set Window Size  ${USERS.users['${username}'].size[0]}  ${USERS.users['${username}'].size[1]}
    Run Keyword If  'Viewer' not in '${username}'  Login  ${username}


Створити драйвер для Firefox
  [Arguments]  ${username}
  ${download_path}=   get_download_file_path
  ${folderList_param}=   Convert To Integer   2
  ${profile}=   Evaluate   sys.modules['selenium.webdriver'].FirefoxProfile()   sys
  Call Method   ${profile}   set_preference   browser.download.dir   ${OUTPUT_DIR}
  Call Method   ${profile}   set_preference   browser.download.folderList   ${folderList_param}
  Call Method   ${profile}   set_preference   browser.download.manager.showWhenStarting   ${False}
  Call Method   ${profile}   set_preference   browser.download.manager.useWindow   false
  Call Method   ${profile}   set_preference   browser.helperApps.neverAsk.openFile   application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/pdf
  Call Method   ${profile}   set_preference   browser.helperApps.neverAsk.saveToDisk   application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/pdf
  Call Method   ${profile}   set_preference   pdfjs.disabled  ${True}
  Create WebDriver   ${USERS.users['${username}'].browser}   alias=${my_alias}   firefox_profile=${profile}
  Go To   ${USERS.users['${username}'].homepage}

Login
  [Arguments]  ${username}
  Click Element  xpath=//div[@class="authBtn"]/a
  Input Text  name=email  ${USERS.users['${username}'].login}
  Execute Javascript   $('input[name="email"]').attr('rel','CHANGE');
  Wait Until Element Is Visible  name=psw  20
  Input Text  name=psw  ${USERS.users['${username}'].password}
  Click Element  xpath=//button[@class="btn"][contains(text(),"Вхід")]
  Wait Until Page Contains Element  xpath=//div[@class="lname"]


Пошук об’єкта МП по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Go To  ${USERS.users['${username}'].homepage}
  Click Element  //span[contains(text(),"ОБ'ЄКТИ")]
  Select From List By Value  name=filter[object]  assetID
  Input Text  name=filter[search]  ${tender_uaid}
  Wait Until Keyword Succeeds   30 x   10 s  Run Keywords
  ...  Execute Javascript  $(".jivo_shadow").remove()
  ...  AND  Click Element  xpath=//button[@class='btn not_toExtend'][./text()='Пошук']
  ...  AND  Wait Until Page Contains   ${tender_uaid}  5
  Wait Until Page Contains Element  xpath=//span[@class="cdValue"][contains(text(),"${tender_uaid}")]
  Click Element  xpath=//*[contains('${tender_uaid}',text()) and contains(text(), '${tender_uaid}')]/ancestor::div[@class="item relative"]/descendant::a[@class="reverse tenderLink"]
  Wait Until Page Does Not Contain Element   xpath=//form[@name="filter"]
  ${tender_uaid}=  Get Text  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span
  [Return]  ${tender_uaid}


Оновити сторінку з об'єктом МП
  [Arguments]  ${username}  ${tender_uaid}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}


Отримати кількість активів в об'єкті МП
  [Arguments]  ${username}  ${tender_uaid}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  ${number_of_items}=  Get Matching Xpath Count  xpath=//h3[contains(text(), "Склад об'єкту приватизації")]/following-sibling::div/descendant::td[@class="itemNum"]
  ${number_of_items}=  Convert To Integer  ${number_of_items}
  [Return]  ${number_of_items}


Створити об'єкт МП
  [Arguments]  ${username}  ${tender_data}
  ${decisions}=   Get From Dictionary   ${tender_data.data}   decisions
  ${items}=   Get From Dictionary   ${tender_data.data}   items
  ${number_of_items}=  Get Length  ${items}
  Click Element  xpath=//div[contains(text(),"Мій кабінет")]
  Wait Until Element Is Visible  xpath=//div[contains(@class, "um_assets")]/a  30
  Click Element  xpath=//div[contains(@class, "um_assets")]/a
  Wait Until Element Is Visible  xpath=//a[@class="reverse"][contains(text(),"Опубліковані")]  30
  Click Element  xpath=//a[@class="reverse"][contains(text(),"Опубліковані")]
  Click Element  xpath=//div[@class="newTender multiButtons"]/a
  Wait Until Page Contains Element  xpath=//button[@class="save button"][contains(text(),"Створити об'єкт")]
  Click Element  xpath=//button[@class="save button"]
  Wait Until Element Is Visible  xpath=//h3[@class="title bigTitle"][contains(text(),"Рішення про затвердження переліку об’єктів, або про включення нового об’єкта до переліку")]
  Run Keyword And Ignore Error   Click Element   xpath=//a[@class="close icons"]
  Input Text  xpath=//input[@name="data[decisions][0][title]"]  ${decisions[0].title}
  ${decisionDate}=  convert_date_for_decision  ${decisions[0].decisionDate}
  Focus  xpath=//input[@name="data[decisions][0][decisionDate]"]
  Execute Javascript  $("input[name|='data[decisions][0][decisionDate]']").removeAttr('readonly'); $("input[name|='data[decisions][0][decisionDate]']").unbind();
  Input Text  xpath=//input[@name="data[decisions][0][decisionDate]"]  ${decisionDate}
  Input Text  xpath=//input[@name="data[title]"]  ${tender_data.data.title}
  Input Text  name=data[decisions][0][decisionID]  ${decisions[0].decisionID}
  Input Text  xpath=//input[@name="data[description]"]  ${tender_data.data.description}
  Click Element  xpath=//section[@id="multiItems"]
  #Додати предмет МП (item) & код CPV
  :FOR  ${index}  IN RANGE  ${number_of_items}
  \  Run Keyword If  ${index} != 0  Click Element  xpath=//section[@id="multiItems"]/descendant::a[@class="addMultiItem"]
  \  Додати предмет МП  ${items[${index}]}
  Click Element  xpath=(//section[contains(@class, "accordionItem")])[last()]/a
  Input Text   name=data[assetHolder][name]  ${tender_data.data.assetHolder.name}
  Input Text   name=data[assetHolder][identifier][id]  ${tender_data.data.assetHolder.identifier.id}
  Select From List By Value  name=data[assetHolder][identifier][scheme]  ${tender_data.data.assetHolder.identifier.scheme}
  Click Element   xpath=//button[@value='publicate']
  Wait Until Page Contains   Об'єкт опубліковано   30
  ${tender_uaid}=   Get Text   xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span
  [Return]  ${tender_uaid}


Додати предмет МП
  [Arguments]  ${item}
  ${unit_name}=   convert_string_from_dict_dzo   ${item.unit.name}
  ${quantity}=  Convert To String  ${item.quantity}
  ${region}=   convert_string_from_dict_dzo   ${item.address.region}
  ${index}=   Get Element Attribute   xpath=(//div[@class="tenderItemElement tenderItemPositionElement"])[last()]@data-multiline
  Input Text   name=data[items][${index}][description]   ${item.description}
  Input Text   name=data[items][${index}][quantity]   ${quantity}
  Click Element   xpath=//input[@name='data[items][${index}][cav_id]']/preceding-sibling::a
  Select Frame   xpath=//iframe[contains(@src,'/js/classifications/universal/index.htm?lang=uk&shema=SP&relation=true')]
  Run Keyword If   '000000' not in '${item.classification.id}'   Input Text   id=search   ${item.classification.description}
  Wait Until Page Contains   ${item.classification.id}
  Click Element  xpath=//a[contains(@id,'${item.classification.id.replace('-','_')}')]
  Click Element   xpath=//*[@id='select']
  Unselect Frame
  Select From List By Label   name=data[items][${index}][unit_id]   ${unit_name}
  Select From List By Label   name=data[items][${index}][country_id]   ${item.address.countryName}
  Select From List By Label   name=data[items][${index}][region_id]    ${region}
  Input Text   name=data[items][${index}][address][locality]   ${item.address.locality}
  Input Text   name=data[items][${index}][address][streetAddress]   ${item.address.streetAddress}
  Input Text  name=data[items][${index}][address][postalCode]   ${item.address.postalCode}
  Select From List By Value   name=data[items][${index}][registrationDetails][status]  ${item.registrationDetails.status}


Додати актив до об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${item}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[contains(text(),"Редагувати")]
  Click Element  xpath=//a[contains(text(),"Редагувати")]
  Wait Until Element Is Visible  xpath=//h3[@class="title bigTitle"][contains(text(),"Рішення про затвердження переліку об’єктів, або про включення нового об’єкта до переліку")]
  Click Element  xpath=//section[@id="multiItems"]/a
  Click Element  xpath=//section[@id="multiItems"]/descendant::a[@class="addMultiItem"]
  Додати предмет МП  ${item}
  Click Element  xpath=//button[@value="save"]
  Wait Until Element Is Visible  xpath=//td[contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span


Отримати інформацію про decisions
  [Arguments]  ${field}
  ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
  ${index}=  Convert To Integer  ${index}
  ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=//h3[@class="title"][contains(text(), "Найменування рішення про приватизацію об'єкту")]/../descendant::td[@class="itemNum"]/span[contains(text(), "${index + 1}")]/../following-sibling::td/div[1]
  ...  ELSE IF  'decisionDate' in '${field}'  Get Text  //h3[@class="title"][contains(text(), "Найменування рішення про приватизацію об'єкту")]/../descendant::td[@class="itemNum"]/span[contains(text(), "${index + 1}")]/../following-sibling::td/div[2]/span[3]
  ...  ELSE IF  'decisionID' in '${field}'  Get Text  //h3[@class="title"][contains(text(), "Найменування рішення про приватизацію об'єкту")]/../descendant::td[@class="itemNum"]/span[contains(text(), "${index + 1}")]/../following-sibling::td/div[2]/span[1]
  ${value}=  convert_decision_data  ${value}  ${field}
  [Return]  ${value}



#####################################################      ASSETS     ################################################

Отримати інформацію із об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  ${value}=  run keyword if  '${field}' == 'assetID'  Get Text  xpath=//td[contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span
  ...  ELSE IF  'assetCustodian.identifier.legalName' in '${field}'  Get Text  xpath=(//td[contains(text(), "Найменування Органу приватизації")])[1]/following-sibling::td[1]/descendant::span
  ...  ELSE IF  'date' == '${field}'  Get Element Attribute  xpath=//*[@data-test-date]@data-test-date
  ...  ELSE IF  'rectificationPeriod.endDate' in '${field}'  Get Element Attribute  xpath=//*[@data-test-rectificationperiod-enddate]@data-test-rectificationperiod-enddate
  ...  ELSE IF  'status' == '${field}'  Get Text  xpath=//div[contains(@class,"statusItem active")]/descendant::div[contains(@class,"statusName")][last()]
  ...  ELSE IF  'title' == '${field}'  Get Text  xpath=//div/h1
  ...  ELSE IF  'decision' in '${field}'  Отримати інформацію про decisions  ${field}
  ...  ELSE IF  'description' == '${field}'  Get Text  xpath=//h2[@class="tenderDescr"]
  ...  ELSE IF  'assetHolder.name' == '${field}'  Get Text  xpath=(//td[contains(text(), "Найменування Органу приватизації")])[2]/following-sibling::td[1]
  ...  ELSE IF  'assetHolder.identifier.scheme' == '${field}'  Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[2]/following-sibling::td/span[1]
  ...  ELSE IF  'assetHolder.identifier.id' == '${field}'  Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[2]/following-sibling::td/span[2]
  ...  ELSE IF  'assetCustodian.identifier.scheme' == '${field}'  Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[1]/following-sibling::td/span[1]
  ...  ELSE IF  'assetCustodian.identifier.id' == '${field}'  Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[1]/following-sibling::td/span[2]
  ...  ELSE IF  'assetCustodian.identifier.legalName' == '${field}'  Get Text  xpath=(//td[contains(text(), "Юридична адреса")])[1]/following-sibling::td[1]
  ...  ELSE IF  'assetCustodian.contactPoint.name' == '${field}'  Get Text  xpath=(//td[contains(text(), "Ім'я")])[1]/following-sibling::td[1]
  ...  ELSE IF  'assetCustodian.contactPoint.telephone' == '${field}'  Get Text  xpath=(//td[contains(text(), "Телефон")])[1]/following-sibling::td[1]
  ...  ELSE IF  'assetCustodian.contactPoint.email' == '${field}'  Get Text  xpath=(//td[contains(text(),"E-mail")])[1]/following-sibling::td[1]
  ...  ELSE IF  'documents[0].documentType' == '${field}'  Get Text  xpath=//a[contains(@href, "info/ss")]/following-sibling::div/span
  ...  ELSE IF  'dateModified' == '${field}'  Get Element Attribute  xpath=//*[@data-test-date]@data-test-datemodified

  ${value}=  adapt_asset_data  ${field}  ${value}
  [Return]  ${value}


Отримати інформацію з активу об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${item_value}=  Run Keyword If  'classification.scheme' in "${field_name}"  Get Element Attribute  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/./following-sibling::div[1]/span[1]@data-classification-scheme
  ...  ELSE IF  'description' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]
  ...  ELSE IF  'classification.id' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/./following-sibling::div[1]/span[2]
  ...  ELSE IF  'unit.name' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/../following-sibling::td/span[2]
  ...  ELSE IF  'quantity' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/../following-sibling::td/span[1]
  ...  ELSE IF  'registrationDetails.status' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/following-sibling::div[4]/span[1]
  ${item_value}=   adapt_items_data   ${field_name}   ${item_value}
  [Return]  ${item_value}

Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  Execute Javascript   $(".bottomFixed").remove();
  ${file_name}=   Get Text   xpath=//span[contains(text(),'${doc_id}')]
  ${url}=   Get Element Attribute   xpath=//*[contains(text(),'${doc_id}')]/ancestor::*[@class="tenderFullListElement docItem"]/descendant::a@href
  dzo_download_file   ${url}  ${file_name.split('/')[-1]}  ${OUTPUT_DIR}
  [Return]  ${file_name.split('/')[-1]}

Отримати текст із поля і показати на сторінці
  [Arguments]   ${fieldname}
  sleep  1
  ${return_value}=    Get Text  ${locator.${fieldname}}
  [Return]  ${return_value}

Завантажити документ в об'єкт МП з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${type}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[contains(text(),"Редагувати")]
  Wait Until Element Is Visible  xpath=//button[contains(text(),"Зберегти")]
  Click Element  xpath=(//a[@class="accordionOpen icons icon_view"])[2]
  Choose File  xpath=//input[@name="upload"]  ${filepath}
  Wait Until Element Is Visible  xpath=//div[contains(@class,"langSwitch_uk")]/input[contains(@value,"${filepath.split('/')[-1]}")]        #ХОРОШИЙ ЛОКАТОР
  Select From List By Value  xpath=(//*[contains(@class, 'js-documentType')])[last()]  ${type}
  Click Button  xpath=//button[@value='save']
  Sleep  180

Завантажити ілюстрацію в об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  dzo.Завантажити документ в об'єкт МП з типом  ${username}  ${tender_uaid}  ${filepath}  illustration

Внести зміни в об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[contains(text(),"Редагувати")]
  Click Element  xpath=//a[contains(text(),"Редагувати")]
  Run Keyword If  "title" in "${fieldname}"   Input Text  xpath=//input[@name="data[title]"]  ${fieldvalue}
  ...  ELSE IF  "description" in "${fieldname}"   Input Text  xpath=//input[@name="data[description]"]  ${fieldvalue}
  Click Element  xpath=//button[contains(text(),"Зберегти")]
  Wait Until Page Contains Element  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span


Внести зміни в актив об'єкта МП
  [Arguments]  ${username}  ${item_id}  ${tender_uaid}  ${field_name}  ${field_value}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Element Is Visible  xpath=//a[contains(text(),"Редагувати")]
  Click Element  xpath=//a[contains(text(),"Редагувати")]
  Click Element  xpath=(//a[@class="accordionOpen icons icon_view"])[1]
  ${fieldvalue}=  Convert To String  ${field_value}
  Run Keyword If  "quantity" in "${field_name}"   Input Text  xpath=(//input[contains(@value,"${item_id}")])[1]/../../../following-sibling::tr/descendant::input  ${field_value}
  Click Element  xpath=//button[contains(text(),"Зберегти")]
  Wait Until Page Contains Element  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span


Завантажити документ для видалення об'єкта МП
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[@class='button assetCancelCommand']
  Wait Until Element Is Visible  xpath=//div[@class="jContent"]
  Click Element  xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Visible  xpath=//div/h1[contains(text(), "Причина скасування об'єкту")]
  Choose File  xpath=//input[@type="file"]  ${filepath}
  #Wait Until Element Is Visible  xpath=//button[@class="icons icon_upload relative"]
  Wait Until Element Is Not Visible  id=jAlertBack
  Click Element  xpath=//button[contains(text(),"Додати")]
  Wait Until Element Is Visible  xpath=//div[@class="jContent"]
  Click Element  xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Not Visible  xpath=//div/a[@class="jBtn green"]


Видалити об'єкт МП
  [Arguments]  ${username}  ${tender_uaid}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[@class='button assetCancelCommand']
  Wait Until Element Is Visible  xpath=//div[@class="jContent"]
  Click Element  xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Not Visible  id=jAlertBack
  Wait Until Element Is Visible  xpath=//div/h1[contains(text(), "Причина скасування об'єкту")]
  Click Element  xpath=//button[contains(text(),"Зберегти")]
  Wait Until Element Is Visible  xpath=//div[@class="jContent"]
  Click Element  xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Visible  xpath=//div[contains(text(),"Скасування в процесі")]
  Reload Page

########################################    LOTS / ЛОТИ    ####################################################################

Створити лот
  [Arguments]   ${username}  ${tender_data}  ${tender_uaid}
  dzo.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
  Scroll And Click Element  xpath=//a[@class="button"][contains(@href, "/lots/new")]
  Wait Until Element Is Visible  xpath=//h3[@class="title bigTitle"][contains(text(),"Рішення про затвердження умов продажу")]
  ${decisions}=   Get From Dictionary   ${tender_data.data}   decisions
  ${decisionDate}=  convert_date_for_decision  ${decisions[0].decisionDate}
  Execute Javascript  $("input[name|='data[decisions][0][decisionDate]']").removeAttr('readonly'); $("input[name|='data[decisions][0][decisionDate]']").unbind();
  Input Text  xpath=//input[@name="data[decisions][0][decisionDate]"]  ${decisionDate}
  Input Text  name=data[decisions][0][decisionID]  ${decisions[0].decisionID}
  Click Element  xpath=//section[contains(@class, "accordionItem")]/a
  Wait Until Page Contains Element  xpath=//td[contains(text(),"Початкова ціна аукціону")]
  Input Text  name=data[auctions][0][value][amount]  123456
  Input Text  name=data[auctions][0][minimalStep][amount]  100
  Input Text  name=data[auctions][0][guarantee][amount]  2000
  ${date}=  dzo_service.convert date to slash format  2018-10-22T20:13:54.056608+03:00
  Focus  name= data[auctions][0][auctionPeriod][startDate]
  Execute Javascript  $("input[name|='data[auctions][0][auctionPeriod][startDate]']").removeAttr('readonly'); $("input[name|='data[auctions][0][auctionPeriod][startDate]']").unbind();
  Input Text  name=data[auctions][0][auctionPeriod][startDate]  ${date}
  Run Keyword And Ignore Error  Wait Until Element Is Visible  ${date}  20
  Input Text  name=data[auctions][0][bankAccount][description]  Трям Тарарам
  Input Text  name=data[auctions][0][bankAccount][bankName]  Це назва банку Трям Тарарам
  Input Text  name=data[auctions][0][bankAccount][accountIdentification][0][id]  12345678
  Input Text  name=data[auctions][0][bankAccount][accountIdentification][1][id]  123456
  Input Text  name=data[auctions][0][bankAccount][accountIdentification][2][id]  6512
  #Select From List By Value  name= data[auctions][1][tenderingDuration]  35
  #Input Name  name=data[auctions][2][auctionParameters][dutchSteps]  99
  Scroll And Click Element  xpath=//button[@value='publicate']
  Wait Until Page Contains  Перевірка доступності об’єкту  30
  ${lot_id}=  Get Text  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Інформаційного повідомлення")]/following-sibling::td[1]/a/span
  [Return]  ${lot_id}

Пошук лоту по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  Go To  ${USERS.users['${username}'].homepage}
  Click Element  xpath=//span[contains(text(),"ПОВІДОМЛЕННЯ")]
  Select From List By Value  name=filter[object]  lotID
  Input Text  name=filter[search]  ${tender_uaid}
  Wait Until Keyword Succeeds   30 x   10 s  Run Keywords
  ...  Click Element  xpath=//button[@class='btn not_toExtend'][./text()='Пошук']
  ...  AND  Wait Until Page Contains   ${tender_uaid}  5
  Wait Until Page Contains Element  xpath=//span[contains(text(),"${tender_uaid}")]
  Click Element  xpath=//*[contains('${tender_uaid} ',text()) and contains(text(), '${tender_uaid}')]/ancestor::div[@class="item relative"]/descendant::a[@class="reverse tenderLink"]
  Wait Until Page Contains Element  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Інформаційного повідомлення")]/following-sibling::td[1]/a/span
  ${tender_uaid}=  Get Text  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Інформаційного повідомлення")]/following-sibling::td[1]/a/span
  [Return]  ${tender_uaid}


Додати умови проведення аукціону
   [Arguments]  ${username}  ${tender_data}  ${index}  ${tender_uaid}
   Run Keyword If  ${index} == 0  Заповнити умови до першого аукціону  ${username}  ${tender_data}  ${tender_uaid}
   ...  ELSE  Заповнити умови до другого аукціону  ${tender_data}


Заповнити умови до першого аукціону
  [Arguments]   ${username}  ${tender_data}  ${tender_uaid}
  dzo.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
  Wait Until Keyword Succeeds   30 x   10 s  Run Keywords
  ...  Reload Page
  ...  AND  Wait Until Element Is Visible  xpath=//a[contains(text(),"Редагувати")]
  Click Element  xpath=//a[contains(text(),"Редагувати")]
  Wait Until Element Is Visible  xpath=//button[contains(text(),"Зберегти")]
  Click Element  xpath=(//a[@class="accordionOpen icons icon_view"])[3]
  Wait Until Page Contains Element  xpath=//td[contains(text(),"Початкова ціна аукціону")]
  ${value_amount}=  add_second_sign_after_point  ${tender_data.value.amount}
  ${value_minStep_amount}=  add_second_sign_after_point  ${tender_data.minimalStep.amount}
  ${value_guarantie_amount}=  add_second_sign_after_point  ${tender_data.guarantee.amount}
  Input Text  name=data[auctions][0][value][amount]  ${value_amount}
  Input Text  name=data[auctions][0][minimalStep][amount]  ${value_minStep_amount}
  Input Text  name=data[auctions][0][guarantee][amount]  ${value_guarantie_amount}
  ${start_date}=  dzo_service.convert date to slash format  ${tender_data.auctionPeriod.startDate}
  Focus  name= data[auctions][0][auctionPeriod][startDate]
  Execute Javascript  $("input[name|='data[auctions][0][auctionPeriod][startDate]']").removeAttr('readonly'); $("input[name|='data[auctions][0][auctionPeriod][startDate]']").unbind();
  Input Text  name=data[auctions][0][auctionPeriod][startDate]  ${start_date}
  ${auction_time}=  Set Variable  ${tender_data.auctionPeriod.startDate[11:19]}
  Execute Javascript   $("input[name='auctionPeriod_time']").val("${auction_time}");
  #Input Text  name=data[auctions][0][bankAccount][description]  ${tender_data.bankAccount.description}
  ${account}=  Get From Dictionary  ${tender_data.bankAccount}  accountIdentification
  Input Text  name=data[auctions][0][bankAccount][bankName]  ${tender_data.bankAccount.bankName}
  ${bank_id}=  adapt_edrpou  ${account[0].id}
  Input Text  name= data[auctions][0][bankAccount][accountIdentification][0][id]  ${bank_id}                                #ЄДРПОУ
  ${tax}=  Convert To String   ${tender_data.value.valueAddedTaxIncluded}
  ${tax}=  Convert To Lowercase  ${tax}
  Select From List By Value  name= data[auctions][0][value][valueAddedTaxIncluded]  ${tax}                                  #пдв

Заповнити умови до другого аукціону
  [Arguments]  ${tender_data}
  ${auction_duration}=  convert_duration   ${tender_data.tenderingDuration}
  Select From List By Value  name= data[auctions][1][tenderingDuration]  ${auction_duration}
  Scroll And Click Element  xpath=//button[@value='save']
  Wait Until Element Is Visible  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Інформаційного повідомлення")]/following-sibling::td[1]/a/span
  Wait Until Page Contains  Опубліковано  30


Отримати інформацію із лоту
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  ${value}=  Run Keyword If  '${field}' == 'lotID'                   Get Text  xpath=//td[contains(text(),"Ідентифікатор Інформаційного повідомлення")]/following-sibling::td[1]/a/span
  ...  ELSE IF  'status' == '${field}'                               Get Text  xpath=//div[contains(@class,"statusItem active")]/descendant::div[contains(@class,"statusName")][last()]
  ...  ELSE IF  'assetCustodian.identifier.legalName' in '${field}'  Get Text  xpath=(//td[contains(text(), "Найменування Органу приватизації")])[1]/following-sibling::td[1]/descendant::span
  ...  ELSE IF  'date' == '${field}'                                 Get Element Attribute  xpath=//*[@data-test-date]@data-test-date
  ...  ELSE IF  'rectificationPeriod.endDate' in '${field}'          Get Element Attribute  xpath=//*[@data-test-rectificationperiod-enddate]@data-test-rectificationperiod-enddate
  ...  ELSE IF  'title' == '${field}'                                Get Text  xpath=//div/h1

#lotholder балансоутримувач

  ...  ELSE IF  'lotHolder.name' == '${field}'                       Get Text  xpath=(//td[contains(text(), "Найменування Органу приватизації")])[2]/following-sibling::td[1]
  ...  ELSE IF  'lotHolder.identifier.scheme' == '${field}'          Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[2]/following-sibling::td/span[1]
  ...  ELSE IF  'lotHolder.identifier.id' == '${field}'              Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[2]/following-sibling::td/span[2]

#lotcustodian розпорядник

  ...  ELSE IF  'lotCustodian.identifier.scheme' == '${field}'       Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[1]/following-sibling::td/span[1]
  ...  ELSE IF  'lotCustodian.identifier.id' == '${field}'           Get Text  xpath=(//td[contains(text(), "Код в ЄДРПОУ / ІПН")])[1]/following-sibling::td/span[2]
  ...  ELSE IF  'lotCustodian.identifier.legalName' == '${field}'    Get Text  xpath=(//td[contains(text(), "Найменування Органу приватизації")])[1]/following-sibling::td[1]
  ...  ELSE IF  'lotCustodian.contactPoint.name' == '${field}'       Get Text  xpath=(//td[contains(text(), "Ім'я")])[1]/following-sibling::td[1]
  ...  ELSE IF  'lotCustodian.contactPoint.telephone' == '${field}'  Get Text  xpath=(//td[contains(text(), "Телефон")])[1]/following-sibling::td[1]
  ...  ELSE IF  'lotCustodian.contactPoint.email' == '${field}'      Get Text  xpath=(//td[contains(text(),"E-mail")])[1]/following-sibling::td[1]
#  ...  ELSE IF  'dateModified' == '${field}'                         Get Element Attribute  xpath=//*[@data-test-date]@data-test-datemodified

  ${value}=  adapt_asset_data  ${field}  ${value}
  [Return]  ${value}


Отримати інформацію зі складу інформаційного повідомлення
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${item_value}=  Run Keyword If  'classification.scheme' in "${field_name}"  Get Element Attribute  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/./following-sibling::div[1]/span[1]@data-classification-scheme
  ...  ELSE IF  'description' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]
  ...  ELSE IF  'classification.id' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/./following-sibling::div[1]/span[2]
  ...  ELSE IF  'quantity' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/../following-sibling::td/span[1]
  ...  ELSE IF  'unit.name' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/../following-sibling::td/span[2]
  ...  ELSE IF  'registrationDetails.status' == '${field_name}'  Get Text  xpath=//div[@class="itemDescr"][contains(text(), "${item_id}")]/following-sibling::div[4]/span[1]
  ${item_value}=   adapt_items_data   ${field_name}   ${item_value}
  [Return]  ${item_value}


Отримати інформацію про lotDecisions
  [Arguments]  ${field}
  ${index}=  Set Variable  ${field.split('[')[1].split(']')[0]}
  ${index}=  Convert To Integer  ${index}
  ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=//h3[@class="title"][contains(text(), "Рішення про затвердження умов продажу")]/../descendant::td[@class="itemNum"]/span[contains(text(), "${index + 1}")]/../following-sibling::td/div[1]
  ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=(//h3[@class="title"][contains(text(), "Рішення про затвердження умов продажу")]/following-sibling::div/descendant::span[contains(text(), "від")])[${index + 1}]/following-sibling::span
  ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=(//h3[@class="title"][contains(text(), "Рішення про затвердження умов продажу")]/following-sibling::div/descendant::span[contains(text(), "від")])[${index + 1}]/preceding-sibling::span
  ${value}=  convert_decision_data  ${value}  ${field}
  [Return]  ${value}


Завантажити документ для видалення лоту
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  dzo.Пошук лоту по ідентифікатору    ${username}  ${tender_uaid}
  Click Element                       xpath=//a[@class='button lotCancelCommand']
  Wait Until Element Is Visible       xpath=//div[@class="jContent"]
  Click Element                       xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Not Visible   xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Visible       xpath=//div/h1[contains(text(), "Причини скасування Інформаційного повідомлення")]
  Choose File                         xpath=//input[@type="file"]  ${filepath}
  Wait Until Element Is Visible       xpath=//button[@class="icons icon_upload relative"]
  Wait Until Element Is Not Visible   id=jAlertBack
  Click Element                       xpath=//button[contains(text(),"Додати")]
  Wait Until Element Is Visible       xpath=//div[@class="jContent"]
  Click Element                       xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Not Visible   xpath=//div/a[@class="jBtn green"]

Видалити лот
  [Arguments]  ${username}  ${tender_uaid}
  dzo.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
  Click Element  xpath=//a[@class='button lotCancelCommand']
  Wait Until Element Is Visible  xpath=//div/a[@class="jBtn green"]
  Click Element  xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Not Visible  id=jAlertBack
  Wait Until Element Is Visible  xpath=//div/h1[contains(text(), "Причини скасування Інформаційного повідомлення")]
  Click Element  xpath=//button[contains(text(),"Зберегти")]
  Wait Until Element Is Visible  xpath=//div[@class="jContent"]
  Click Element  xpath=//div/a[@class="jBtn green"]
  Wait Until Element Is Visible  xpath=//div[contains(text(),"Скасування в процесі")]
  Reload Page



Scroll And Click Element
  [Arguments]  ${locator}
  Wait Until Element Is Visible   ${locator}   20
  Scroll To Element  ${locator}
  Click Element  ${locator}

Scroll To Element
  [Arguments]  ${locator}
  ${elem_vert_pos}=  Get Vertical Position  ${locator}
  Execute Javascript  window.scrollTo(0,${elem_vert_pos - 200});

Оновити сторінку з лотом
  [Arguments]  ${username}  ${tender_uaid}
  dzo.Пошук лоту по ідентифікатору  ${username}  ${tender_uaid}
