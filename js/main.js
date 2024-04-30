
function msg(msg){
  let div = document.createElement('DIV')
  div.className = "message"
  div.innerHTML = msg
  MSG_FIELD.appendChild(div)
}
function checkSite(){
  let site_url = document.querySelector('#site_url').value
  msg("Je dois checker le site " + site_url)
  IFRAME.src = site_url
  // IFRAME2.src = site_url
}
function checkOnLoad(iframe){
  console.log("iframe", iframe)
  console.log("iframe.contentWindow", iframe.contentWindow)
  msg("Je checke au chargement.")
  var links = iframe.contentDocument.links
  console.log("links = ", links, links.class)
  // On met tous les liens de côté
  var linklist = []
  for (var link of links) {linklist.push(link)}
  linklist.forEach(link => {
    if ( CHECKED_LINKS[link] ){
      CHECKED_LINKS[link] += 1
      return
    }
    else Object.assign(CHECKED_LINKS, {[link]: 1})
    IFRAME.src = link
  })
}

const CHECKED_LINKS = {}
const IFRAME = document.querySelector('#target')
const MSG_FIELD = document.querySelector('#message')
