# -*- coding: utf-8 -*-
'''
author = Kwan Tak Hei Fergus
phone = "+852 61255752"
email = "takhei611@gmail.com"
'''

# web scrapping
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
from bs4 import BeautifulSoup
from selenium import webdriver

# data transformation
import pandas as pd
import numpy as np

# misc
import warnings
from io import StringIO
import os
import time
from datetime import date
from datetime import datetime

# ending email
import smtplib 
from email.mime.multipart import MIMEMultipart 
from email.mime.text import MIMEText 
from email.mime.base import MIMEBase 
from email import encoders 

# ignore warnings
warnings.filterwarnings("ignore")

# chmod +x ./job.sh
# To run the program, run this line in the bash: ./job.sh

# main function
def handler(event, context):
    # Funds part
    
    # NAV sometimes has error and sometimes doesn't, here we try to take the data until there is no error. If error, it will automatically rerun the PBOC part.
    print('NAV...')
    NAV_connected = False
    while not NAV_connected:
        try:
            NAV = NAV_function()
            NAV_connected = True
        except:
            print("Error, trying to retrieve NAV data again...")
            pass
    
    print('Company...')
    company = company_function()
    
    # merging the data together
    fund_output = NAV.merge(company, how='left', on='code').sort_values('code') # use left because the funds in fund_output are all the public funds, but right has other funds
    
    # Renaming the columns, filter unecessary columns
    fund_output = fund_output.rename(columns={'code':'Code', 'inception_date':'Inception Date', 'manager':'Manager', 'number_of_unit':'Number Of Unit', 'per_unit_NAV':'Per Unit NAV', 'recent_unit':'Recent Unit', 'company':'Company','fund':'Fund','link':'Link'})
    fund_output = fund_output[['Code', 'Fund', 'Inception Date', 'Per Unit NAV', 'Number Of Unit', 'AUM', 'Manager', 'Company', 'Link']]
    fund_output.sort_values(by=['Code'], inplace=True)
        
    print('Fund Done')
    
    
    # News part
    print('industry news...')
    industry_news = industry_news_function()
    print('SAFE...')
    SAFE = SAFE_function()
    print('Ignites Asia...')
    IgnitesAsia = IgnitesAsia_function()
    
    # PBOC sometimes has error and sometimes doesn't, here we try to take the data until there is no error. If error, it will automatically rerun the PBOC part.
    print('PBOC...')
    PBOC_connected = False
    while not PBOC_connected:
        try:
            PBOC = PBOC_function()
            PBOC_connected = True
        except:
            print("Error, trying to retrieve PBOC data again...")
            pass
    
    # merging the data together
    news_output = pd.concat([IgnitesAsia, industry_news], ignore_index = True)
    news_output = pd.concat([news_output,SAFE], ignore_index=True)
    news_output = pd.concat([news_output, PBOC], ignore_index = True)
    news_output = news_output[news_output['Date'] != ' ']
    news_output = news_output[['Date', 'News', 'Summary', 'News Type', 'Link']]
    
    print('News Done')
    
    
    # Send Email
    # Create a list to store the fund data and news data, and another list to store the name to be given to the data file.
    print('Sending email...')
    writer = pd.ExcelWriter('data.xlsx')
    fund_output.to_excel(writer, sheet_name='funds_data', index=False, encoding='utf-8')
    news_output.to_excel(writer, sheet_name='news_data', index=False, encoding='utf-8')
    writer.save()

    send_email('data.xlsx')
    
    print('All done!')
    
    return 
    
def NAV_function():
    # To take the name, code, AUM (in millions), NAV, number of units, manager, inception date and link of the funds
    # return code, name, per_unit_NAV, number_of_unit, AUM, inception_date, manager
    
    # get the webpage
    url = 'http://vip.stock.finance.sina.com.cn/fund_center/index.html#jjgmall'
    driver = webdriver.PhantomJS(r"/home/ubuntu/environment/lib/phantomjs_2.1.1", service_log_path=os.path.devnull)
    driver.get(url)
    
    # find useful elements and take all the necessary data
    output = pd.DataFrame()
    while True:        
        #make the source text to list of list
        table = driver.find_element_by_tag_name('tbody')
        table = table.text.split("\n")
        table = [ele.split(" ") for ele in table]
    
        #transform list of list of data of the funds to table
        tmp_output = pd.DataFrame(table)
        tmp_output = tmp_output.iloc[:,1:8]
        tmp_output.columns=(['code', 'name', 'per_unit_NAV', 'number_of_unit', 'AUM', 'inception_date', 'manager'])
        
        output = pd.concat([output, tmp_output], ignore_index=True)
        
        #clicking next page and sleep
        try:
            next_page = driver.find_element_by_link_text('下一页')
            next_page.location_once_scrolled_into_view
            next_page.click()
        except:
            #If there is not 'next page' in the web to click, we will exit the loop.
            break
        
        time.sleep(2)

    # convert blank data and calculate AUM
    output['number_of_unit'] = np.where(output['number_of_unit'] == '--', '', output['number_of_unit'])
    output['per_unit_NAV'] = np.where(output['per_unit_NAV'] == '--', '', output['per_unit_NAV'])
    output['AUM'] = np.where(output['AUM'] == '--', 0, output['AUM'].str.replace(',','').astype(int) * 100)
    
    return output
    
def company_function():
    # To match the company in which all the funds belong to
    # return code, company, fund name, link
    
    # get the webpage
    url = 'http://money.finance.sina.com.cn/fund/view/vNewFund_FundCompanyListings.php'
    page = requests.get(url)
    
    # translate the source code into readable text, and search for useful element
    soup = BeautifulSoup(page.content,'html.parser', fromEncoding="gb18030")
    tables = soup.find_all("table", width="100%")
    companies = soup.find_all('div', class_='s11')
    
    # Take all the codes and name of funds to ensure that we do not miss any funds
    output = pd.DataFrame()
    for i in range(len(tables)):
        company = companies[i].text
        fund = tables[i].find_all('a', title=True)
        tmp_output = pd.DataFrame([[company] * len(fund), [ele.text for ele in fund], [ele['href'] for ele in fund]]).T
        output = pd.concat([output,tmp_output], ignore_index=True)
        
    # merge all data into a single table
    output.columns=['company', 'fund', 'link']
    output['code'] = output['fund'].str[-7:-1]
    output['fund'] = output['fund'].str[:-8]
    return output
    
def industry_news_function():
    # To take industry news of public funds in China
    # return date, news, link, news type
    
    # get the webpage
    url = 'http://finance.sina.com.cn/roll/index.d.html?cid=56948&page=1'
    page = requests.get(url)
    
    # translate the source code into readable text, and search for useful element
    soup = BeautifulSoup(page.content, 'html.parser', fromEncoding="gb18030")
    soup = soup.find_all('li')
    soup = [ele for ele in soup if ele.span != None]
    
    # take the industry_news, dates and link
    industry_news = []
    dates = []
    link = []
    for ele in soup:
        industry_news.append(ele.contents[0].contents[0])
        dates.append('2019-' + ele.span.contents[0][1:6].replace('月','-'))
        link.append(soup[0].contents[0]['href'])
        
    # merge the data into a single table
    output = pd.DataFrame({'News':industry_news, 'Link':link, 'Date':dates})
    output['News Type'] = 'Industry News'
    return output    

def SAFE_function():
    # To take the reports and publications published by SAFE
    # return news, link, date, news_type
    
    # get the webpage
    url = 'http://www.safe.gov.cn/safe/zcfg/index.html'
    page = requests.get(url)
    
    # translate the source code into readable text, and search for useful element
    soup = BeautifulSoup(page.content, 'html.parser', fromEncoding="gb18030")
    soup = soup.find_all("div", class_="main_m")[0]
    soup = soup.find_all("div", class_="right_list")[0]
    
    # taking all the necessary data
    dates = [ele.contents[0] for ele in soup.find_all('dd')]
    soup = soup.find_all('a', title=True, href=True)
    output = {}
    for a in soup:
        output[a['title']] = 'www.safe.gov.cn/' + a['href']
    
    output.pop('下一页', None)
    output.pop('尾页', None )
    
    # merge all data into a single table
    output = pd.DataFrame(output.items(), columns=['News','Link'])
    output['Date'] = dates
    output['News Type'] = 'SAFE'
    return output
    
def IgnitesAsia_function():
    my_username = '************'
    my_password = '********'
    
    # Getting the webpage of ignitesasia
    url = 'https://www.ignitesasia.com/'
    driver = webdriver.PhantomJS(r'/home/ubuntu/environment/lib/phantomjs_2.1.1', service_log_path=os.path.devnull)
    driver.get(url)

    # Click to log in page
    login = driver.find_elements_by_class_name('btn')
    login = login[3]
    login.click()
    
    # Find the area to input username and password, and then click log in
    username = driver.find_element_by_id('username')
    password = driver.find_element_by_id('password')
    login = driver.find_element_by_tag_name('button')
    username.send_keys(my_username)
    password.send_keys(my_password)
    login.click()

    # transition to China region ignitesasia
    driver.get('https://www.ignitesasia.com/category/170')

    # Scrapping news, titles, summary and dates
    news = driver.find_element_by_id('main')

    titles = news.find_elements_by_tag_name('h4')
    links = [ele.find_element_by_tag_name('a').get_attribute('href') for ele in titles]
    titles = [ele.text for ele in titles]

    dates = news.find_elements_by_tag_name('p')
    dates = [ele.text[:-11] for ele in dates]
    dates = [datetime.strptime(ele, '%B %d, %Y').strftime('%Y-%m-%d') for ele in dates]

    summary = []
    for x in range(1,11):
        summary.append(news.find_element_by_xpath('//*[@id="main"]/div/div[{}]/div/div'.format(x)).text)

    # Merge all data into a single table
    output = pd.DataFrame([dates, titles, summary, links]).T
    output.columns = ['Date', 'News', 'Summary', 'Link']
    output['News Type'] = 'IgnitesAsia'
    
    return output

def PBOC_function():
    # To take the reports and publications published by PBOC
    # return news, link, date, news_type
    
    # list all the necessary page
    law = 'http://www.pbc.gov.cn/tiaofasi/144941/144951/index.html'
    administration = 'http://www.pbc.gov.cn/tiaofasi/144941/144953/index.html'
    rules = 'http://www.pbc.gov.cn/tiaofasi/144941/144957/index.html'
    documentation = 'http://www.pbc.gov.cn/tiaofasi/144941/3581332/index.html'
    others = 'http://www.pbc.gov.cn/tiaofasi/144941/144959/index.html'
    urls = (law, administration, rules, documentation, others)
    names = ('国家法律', '行政法规', '部门规章', '主要有效规范性文件', '其他文件')
    
    # Loop through all the pages and take their contents
    output = pd.DataFrame()
    for i in range(len(urls)):
        url = urls[i]
        name = names[i]
        
        driver = webdriver.PhantomJS(r'/home/ubuntu/environment/lib/phantomjs_2.1.1', service_log_path=os.path.devnull)
        driver.get(url)
        
        time.sleep(10)
        driver.refresh()
        
        table = driver.find_element_by_id('r_con')
        news = table.text.split('\n')
        
        news = news[:-2]
        news[0] = news[0].strip()
        date = [ele[-10:] for ele in news]
        
        soup = BeautifulSoup(driver.page_source, 'html.parser', fromEncoding="gb18030")
        link = soup.find_all('td', align='left', height='22')
        link = ['http://www.pbc.gov.cn' + ele.contents[0].contents[0]['href'] for ele in link]
        
        tmp_output = pd.DataFrame([news, date, link]).T
        tmp_output.columns = ['News', 'Date', 'Link']
        tmp_output['News Type'] = 'PBOC - ' + name
        output = pd.concat([output, tmp_output], ignore_index=True)
    
    output.dropna()
    return output
    
def send_email(filename):
    fromaddr = "*********t@gmail.com"
    toaddr = "*******@gmail.com"
    
    msg = MIMEMultipart() 
    msg['From'] = fromaddr 
    msg['To'] = toaddr 
    
    msg['Subject'] = "Funds and News data from Echo Kwan CUHK"
    body = """Dear Mr.,

I am writing to send you the news data. Attached is the data required. Please contact me if you have any difficulties. Thank you.
    
Best regards,
Kwan Tak Hei Fergus
    """
    
    msg.attach(MIMEText(body, 'plain')) 
    
    with open(filename, "rb") as attachment:
        p = MIMEBase('application', 'octet-stream') 
        p.set_payload(attachment.read())
        
    encoders.encode_base64(p) 
    p.add_header('Content-Disposition', "attachment; filename= %s" % filename) 
    msg.attach(p) 
    
    s = smtplib.SMTP('smtp.gmail.com', 587) 
    s.starttls() 
    s.login(fromaddr, "********")
    
    text = msg.as_string() 
    s.sendmail(fromaddr, toaddr, text) 
    s.quit() 
    return

if __name__== "__main__":
    handler(0,0)
