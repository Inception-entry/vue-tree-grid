read -p "提交注释信息:"  val
echo $val
git add --all
git commit -m $val
git pull
git push origin master