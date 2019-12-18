# China Funds Data and News Scrapper
This is a server produced by Fergus Kwan Tak Hei to automatically receive China funds data and news from various sources in the web. The server is written in python 3.7, Linux Ubuntu environment and deployed in AWS.

### AWS
- The server is built in AWS lambda (serverless function).
- It is written in the Cloud9 IDE
- It would not exceeds the usage of free tier.

### Requirements
- Please refer to the requirements.txt
### Usage
- After running the bash script, It would automatically run at 11 pm everyday.
- It would first capture Chinese funds data (name, manager, AUM, NAV, inception date, company, no. of units)
- Then capture Chinese funds related news from various sources (Ignite Asia, PBOC, SAFE, SINA)
- After capturing all the data and news, it would send an email with the data attached.
### Sources
- Huge thanks to the reliability of SINA funds.
- Other sources:
-  - PBOC
-  - SAFE
-  - IgniteAsia
