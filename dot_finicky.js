// Use https://finicky-kickstart.now.sh to generate basic configuration
// Learn more about configuration options: https://github.com/johnste/finicky/wiki/Configuration

const chromeProfiles = {
  personal:  "Profile_personal",   // oleg.barenboim@gmail.com
  chessbyte: "Profile_chessbyte",  // chessbyte@gmail.com
  dfinitiv:  "Profile_dfinitiv",   // oleg.barenboim@dfinitiv.io
  "8pawns":  "Profile_8pawns",     // oleg.barenboim@8pawns.com
}

module.exports = {
  defaultBrowser: "Safari",

  handlers: [
    {
      match: /^https?:\/\/linear\.app\/.*$/,
      browser: "/Applications/Linear.app"
    },
    {
      match: /^https?:\/\/.*\.notion.so\/.*$/,
      browser: "/Applications/Notion.app"
    },
    {
      match: /^https?:\/\/.*\.canva.com\/.*$/,
      browser: "/Applications/Canva.app"
    },
    {
      match: /^https?:\/\/.*\.figma.com\/.*$/,
      browser: "/Applications/Figma.app"
    },
    // {
    //   match: /^https?:\/\/.*\.visualstudio\.com\/.*$/,
    //   browser: "/Applications/Visual Studio Code",
    // },
    {
      // Open in Google Chrome (dfinitiv)
      match: [
        "google.com*", // match google.com urls
        finicky.matchDomains(/.*\.google.com/), // use helper function to match on domain only
        finicky.matchDomains(/.*\.notion.so/),  // use helper function to match on domain only
        finicky.matchDomains(/.*\.canva.com/),  // use helper function to match on domain only
        finicky.matchDomains(/.*\.figma.com/),  // use helper function to match on domain only
        finicky.matchDomains(/.*\.miro.com/),   // use helper function to match on domain only
        finicky.matchDomains(/.*\.linear.app/), // use helper function to match on domain only
        "github.com/dfinitiv*",
        "github.com/chessbyte/dfinitiv*",
        "github.com/search?q=org%3Adfinitiv*",
        "dfinitiv.awsapps.com/*"
      ],
      browser: {
        name: "Google Chrome",
        profile: chromeProfiles.dfinitiv
      }
    },
    {
      // Open in Google Chrome (chessbyte)
      match: [
        "github.com/ManageIQ*",
        "github.com/chessbyte/manageiq*",
        "manageiq.org*"
      ],
      browser: {
        name: "Google Chrome",
        profile: chromeProfiles.chessbyte
      }
    },
    {
      // Open in Google Chrome (personal: oleg.barenboim@gmail.com)
      match: [
        finicky.matchDomains(/medium.com/),  // use helper function to match on domain only
      ],
      browser: {
        name: "Google Chrome",
        profile: chromeProfiles.personal
      }
    },
    {
      // Open in Google Chrome (8pawns)
      match: [
        "github.com/8pawns*",
        "github.com/chessbyte/8pawns*",
        "github.com/search?q=org%3A8pawns*",
        "8pawns.awsapps.com/*"
      ],
      browser: {
        name: "Google Chrome",
        profile: chromeProfiles['8pawns']
      }
    },
  ]
}
