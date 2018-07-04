*** Settings ***
Documentation               This is the basic test
Library  Selenium2Library
Library  String
Library  DateTime
Library  dzo_service.py
Library  Collections

*** Variables ***
${decisionID}  Some_DecisionID_#93498494
${locator.assetId}  xpath=//td[@class="nameField"][contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span

*** Keywords ***
Підготувати дані для оголошення тендера
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  ${tender_data}=   adapt_data_for_role   ${role_name}   ${tender_data}
  Log Many   ${tender_data}
  [Return]  ${tender_data}


Підготувати клієнт для користувача
  [Arguments]  ${username}
  Set Global Variable   ${DZO_MODIFICATION_DATE}   ${EMPTY}
  Set Suite Variable  ${my_alias}  ${username + 'CUSTOM'}
  Run Keyword If   "${USERS.users['${username}'].browser}" == "Firefox"   Створити драйвер для Firefox   ${username}
  ...   ELSE   Open Browser   ${USERS.users['${username}'].homepage}   ${USERS.users['${username}'].browser}   alias=${my_alias}
  Set Window Size   @{USERS.users['${username}'].size}
  Set Window Position   @{USERS.users['${username}'].position}
  Run Keyword If   'Viewer' not in '${username}'   Login   ${username}
  
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


#######################################################МІЙ КОД##########################################################


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
  Click Element  xpath=//button[contains(@class, "not_toExtend")]
  Wait Until Page Contains Element  xpath=//span[@class="cdValue"][contains(text(),"${tender_uaid}")]
  Click Element  xpath=//*[contains('${tender_uaid}',text()) and contains(text(), '${tender_uaid}')]/ancestor::div[@class="item relative"]/descendant::a[@class="reverse tenderLink"]
  Wait Until Page Does Not Contain Element   xpath=//form[@name="filter"]
  ${tender_uaid}=  Get Text  ${locator.assetId}
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
  Wait Until Element Is Visible  xpath=//div[contains(@class, "um_assets")]/a  20
  Click Element  xpath=//div[contains(@class, "um_assets")]/a
  Wait Until Element Is Visible  xpath=//a[@class="reverse"][contains(text(),"Опубліковані")]  20
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
  Input Text  name=data[decisions][0][decisionID]  ${decisionID}}
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
  ${tender_uaid}=   Get Text   ${locator.assetId}
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
  Wait Until Page Contains  xpath=//a[contains(text(),"Редагувати")]
  Click Element  xpath=//a[contains(text(),"Редагувати")]
  Wait Until Element Is Visible  xpath=//h3[@class="title bigTitle"][contains(text(),"Рішення про затвердження переліку об’єктів, або про включення нового об’єкта до переліку")]
  Click Element  xpath=//section[@id="multiItems"]/a
  Click Element  xpath=//section[@id="multiItems"]/descendant::a[@class="addMultiItem"]
  Додати предмет МП  ${item}
  Click Element  xpath=//button[@value="save"]
  Wait Until Element Is Visible  xpath=//td[contains(text(),"Ідентифікатор Об'єкту")]/following-sibling::td[1]/a/span

