git-branches () {
  echo
  git for-each-ref --sort=-committerdate refs/heads --format='%(color:blue)%(authordate:format:%Y-%m-%d %I:%M %p) (%(color:blue)%(authordate:relative)%(color:reset))     %(color:reset)%(color:red)%(objectname:short)%(color:reset)  %(color:yellow)%(refname:short)%(color:reset)  %(color:green)%(upstream:short)%(color:reset)'
  echo
}
