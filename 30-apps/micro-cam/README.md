# 0) prep a clean workspace
mkdir -p ~/tmp && cd ~/tmp

# 1) get the repo and the bundle
git clone git@github.com:allenwmoorejr/micro-cam.git
cd micro-cam
# put the downloaded ZIP next to this directory and unzip:
unzip ~/Downloads/micro-cam-starter.zip
# move contents into repo (structure: micro-cam/... )
rsync -av micro-cam/ ./
rm -rf micro-cam

# 2) review / customize
git add .
git commit -m "feat: initial micro-cam (uno r4 + uploader + relay + k8s + helm + ci)"

# 3) push
git push origin main

