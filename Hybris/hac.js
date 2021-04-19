const express = require('express')
const app = express()
const puppeteer = require('puppeteer')
const process = require('process')
const fs = require('fs')

let args = process.argv.slice(2)

//install node js oh rhel
//curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash -
//yum install nodejs
//node -v
//npm -v

// yum install the foll packages
// pango.x86_64
// libXcomposite.x86_64
// libXcursor.x86_64
// libXdamage.x86_64
// libXext.x86_64
// libXi.x86_64
// libXtst.x86_64
// cups-libs.x86_64
// libXScrnSaver.x86_64
// libXrandr.x86_64
// GConf2.x86_64
// alsa-lib.x86_64
// atk.x86_64
// gtk3.x86_64
// ipa-gothic-fonts
// xorg-x11-fonts-100dpi
// xorg-x11-fonts-75dpi
// xorg-x11-utils
// xorg-x11-fonts-cyrillic
// xorg-x11-fonts-Type1
// xorg-x11-fonts-misc

//CD to file location
//npm init -y
//npm i express puppteer 

const ChromiumRevision = require('puppeteer/package.json').puppeteer.chromium_revision
const Downloader = require('puppeteer/utils/ChromiumDownloader')
const revisionInfo = Downloader.revisionInfo(Downloader.currentPlatform(), ChromiumRevision)
process.env.CHROMIUM_BIN = revisionInfo.executablePath
//If you can't download puppteer, replace 'puppeteer' with 'puppeteer-core', change it in declaration and comment out the last four lines
//npm i puppeteer-core
//npm uninstall puppeteer

//Transfer your chromium binary
//from https://crrev.com/638691 - change chromium ver with the one mentioned in the puppeteer-core
//for best compatibility

//Run the script with 'node hac.js <ARG1> <ARG2> ... <ARG13> <PORTNO>'
//Where I've served DEV screenshots on 2998 and QA on 2999.
//Delete/Add extra Args

//go to your hac -> dump configuration, copy the impexes you want to apply to this
let options = {
    'initMethod': args[1],
    'createEssentialData': args[2],
    'localizeTypes': args[3],
    'isagenixcore_sample': args[4],
    'isagenixpromotions_sample': args[5],
    'isagenixinitialdata_sample': args[6],
    'isagenixinitialdata_importSampleData': args[7],
    'isagenixfulfilmentprocess_sample': args[8],
    'isagenixcockpits_sample': args[9],
    'isagenixcockpits_importCustomReports': args[10],
    'isagenixfacades_sample': args[11],
    'isagenixbackoffice_sample': args[12],
    'isagenixcommercewebservices_sample': args[13]
}
let PORT = args[14]

//I set up Nginx to proxy my nodejs processes
//and served images on <url>/hacD && <url>/HacQ for ports 2888 and 2889
let vHost = ''
if(args[0]=='DEV'){
    vHost = 'hacD'
}else if(args[0]=='QA'){
    vHost = 'hacQ'
}

//if you aren't proxying links, replace the next 5 lines with
//app.use(express.static('public'))
if(args[0] == 'testing'){
    app.use(express.static('public'))
}else{
    app.use(`/${vHost}`,express.static('public'))
}

automateWeb = async (type,options) =>{
    //delete 'executable path' if you used 'puppeteer' and not 'puppeteer-core'
    //Replace the value with your chrome binary's path if the latter
    const browser = await puppeteer.launch({ args: ['--no-sandbox'], headless: true, ignoreHTTPSErrors: true, executablePath: '/home/jenkins/nodeScripts/chrome-linux/chrome' })
    try {
        const page = await browser.newPage()
        let URL = ''

        //Change URL for your environment
        if(type=='DEV'){
            URL = 'https://10.1.40.103:9002'
        }else if(type=='QA'){
            URL = 'https://10.1.70.156:9002'
        }else if(type=='testing'){               
            URL = 'https://localhost:9002'
        }
        
        if(type=='testing'){
            await page.goto(`${URL}/login.jsp`)
        }else{
            await page.goto(`${URL}/hac/login.jsp`,{timeout: 0})
        }

        if(fs.existsSync(`public/${type}.png`)){
            console.log(`Deleting previous Screenshot for type ${type}!`)
            fs.unlinkSync(`public/${type}.png`)
        }

        let ssId = setInterval(async ()=>{
            await page.screenshot({path: `public/${type}.png`, fullPage: true})
        },5000)

        if(type=='testing'){
            console.log(`Images are served at: http://localhost:${PORT}/${type}.png`)
        }else{
            //if no proxying
            //replace with console.log(`Images are served at: http://10.1.40.101:${PORT}/${type}.png`)
            console.log(`Images are served at: http://10.1.40.101/${vHost}/${type}.png`)
        }

        await page.focus('input[name=j_password]')
        await page.keyboard.type('nimda')
        await page.click('button[type=submit]')

        console.log(`Logged into HAC!`)
        
        type=='testing'?await page.waitFor(2000):await page.waitForSelector('#pollLast')//// await page.waitForNavigation({'waitUntil': 'networkidle2'})
        
        console.log(`Currently at the Updates page`)

        //open Devtools on your chrome, get the id name of an element after the page loads normally in the selector.
        type=='testing'? await page.waitFor(2000):await page.waitForSelector('#isagenixpromotions_sample')
    
         //Open Devtools, get the id names from the elements, and replace them in the 'options'
        //First three options are true by default, so toggling is false
        options.initMethod=='false'?await page.click('#initMethod'):''
        options.createEssentialData=='false'?await page.click('#createEssentialData'):''
        options.localizeTypes=='false'?await page.click('#localizeTypes'):''

        //check what options are 'true'
        options.isagenixcore_sample=='true'?await page.click('#isagenixcore_sample'):''
        options.isagenixpromotions_sample=='true'?await page.click('#isagenixpromotions_sample'):''

        //check with options have drop-down elements, sub them in 'page.select..'
        if(options.isagenixinitialdata_sample=='true'){
            await page.click('#isagenixinitialdata_sample')
            await page.select('#isagenixinitialdata_importSampleData', options.isagenixinitialdata_importSampleData)
        }
        options.isagenixfulfilmentprocess_sample=='true'?await page.click('#isagenixfulfilmentprocess_sample'):''

        if(options.isagenixcockpits_sample=='true'){
            await page.click('#isagenixcockpits_sample')
            await page.select('#isagenixcockpits_importCustomReports', options.isagenixcockpits_importCustomReports)
        }
        options.isagenixfacades_sample=='true'?await page.click('#isagenixfacades_sample'):''
        options.isagenixbackoffice_sample=='true'?await page.click('#isagenixbackoffice_sample'):''
        options.isagenixcommercewebservices_sample=='true'?await page.click('#isagenixcommercewebservices_sample'):''
       

        await page.click('button[class=buttonExecute]')

        console.log(`The passed options have been clicked, and Updates are now applying!`)
        console.log(options)

        let timer = 0
        let id = setInterval(async ()=>{
            let flag1 = flag2 = false

            //Check for Hyperlink with 'Continue' -> 1st Exit condition
            let linkHandler= await page.$x("//a[contains(text(), 'Continue...')]")
            linkHandler.length > 0? flag1=true : flag2=false
            
            //Check for length (Blank Screen) -> 2nd Exit condition
            //go to console, type 'document.getElementById('mainContainer').innerText.length' to get the length
            //for each environment, after it's applied updates.
            if(type=='QA'){
                let length = await page.$eval('#mainContainer', el => el.innerText.length)
                length == 716? flag2=true:''
            }else if(type=='DEV'){
                let length = await page.$eval('#mainContainer', el => el.innerText.length)
                length == 719? flag2=true:''
            }else if(type=='testing'){
                let length = await page.$eval('#mainContainer', el => el.innerText.length)
            }

            if(flag1 == true || flag2 == true){
                console.log('Updates done applying!')
                flag1?console.log('Continue Link was found!'):console.log('Blank Screen was obtained!')
                clearInterval(ssId)
                clearInterval(id)
                // await page.screenshot({path: `public/${type}.png`, fullPage: true})
                // server.close()
                process.exit(0)
            }else{
                console.log(`Still checking for Update confirmation, elapsed time: ${(timer/60000).toFixed(2)}m`)
                timer+=25000
            }

        },25000)

    } catch (error) {
        console.log(error.message)
        // await page.close()
        await browser.close()
        process.exit(1)
    }
} 

app.listen(PORT,()=>{
    console.log(`Server is running on port ${PORT}`)
})

automateWeb(args[0], options)