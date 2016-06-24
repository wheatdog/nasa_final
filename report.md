# NASA SA1-1 Report

組員名單：
b03902071 葉奕廷
b03902027 王冠鈞
b03902028 劉彥廷

mentor:
b02902001 鄭儒謙

### Outline
1. Project 架構
2. rsync 介紹
3. rsync 與 tar 的比較
4. script 實作方法與定時執行
5. 遇到的困難與改善方法
6. Project 實作結果與截圖
7. 未來方向
8. 參考資料

### Project 架構
scripts 包裝了 `rsync` 來達成讀取 config file 備份與還原。其中包含了兩個script： `backup.sh` 和 `restore.sh` 來分別實現備份與還原。
利用 `crontab` 實現定時自動備份；為了讓每次自動執行中， `rsync` 使用 `ssh` 時不用打密碼，亦必須預先產生一組密碼，將公鑰上傳到遠端。
此外還順便寫了 manual 方便使用者查詢功能；可用 `root` 權限執行 `man_install.sh` 後，即可用 `man xxx.sh` 來查看。
本次 project 的 source code 在下面的連結可以找到。

Project repository link: https://github.com/wheatdog/nasa_final

### rsync 介紹
`rsync` 聲稱是一個多功能、快速的遠端/本機檔案複製/備份工具，亦有資料同步的功能。最常見的(包括本次 project 有用到的)用法就是把本機的檔案傳輸到遠端機器上：
~~~
rsync -avXA src_directory user@remote-host:remote_dest_directory
~~~
其中：
* `-a` 是開啟檔案模式，等於 `-rlptgoD`，包含了 directory 遞迴傳輸、symbolic link、檔案權限、時間、群組、擁有者、及特殊檔案等，但不包含 `ACL`、`xattr` 等屬性。
* `-X` 是保留 `xattr` 屬性。
* `-A` 是保留 `ACL` 屬性。
* `-v` 為輸出執行時的訊息。

`rsync` 預設使用 ssh 來進行傳輸，在輸入指令時，在遠端路徑前是否有加 `-e ssh` 並不影響結果。

此外， `rsync` 除了可以單次呼叫傳輸，它還有提供 daemon mode (本次未用到)：在遠端 server 做好設定後， `rsync` 會預設占用 port 873，當有人從遠端呼叫後，會讀入 server 上 `/etc/rsyncd.conf` 中的設定(該檔預設不存在)，以該設定進行資料處理。在這種場合中，輸入的指令則變為：
~~~
rsync -avXA --password-file=passwd_file_dir \
src_directory user@remote-host::module_name
~~~
在這裡 `--password-file` 必須提供使用者密碼，而遠端 `rsyncd` 會檢查(`rsyncd` 有專門的帳密名單，預設是 `/etc/rsyncd.secret`)，若通過驗證則會採用 `rsyncd.conf` 中 `module_name` 所定義的該組設定。

### rsync 與 tar 的比較
由於在 demo 當天另一組作備份的使用了 `tar` 來進行實作，所以在這裡比較一下 `rsync` 和 `tar` 的差異：
* `tar` 可以選用不同的壓縮格式將檔案壓縮備份，而 `rsync` 有提供 `-z` 等參數來壓縮傳輸時的資料，但並不能壓縮備份。
* `rsync` 內建有強大的選項與功能，包括預設的遠端傳輸功能，而不必額外用 `scp` 等其它指令來實現遠端傳輸。
* `rsync` 透過自己獨特的演算法，可以在短時間內找出和目標資料夾不同的部分而決定要傳輸那些資料，比較符合平時備份的直覺。
* 整體上 `rsync` 在處理遠端資料同步/傳輸比較簡潔、方便，只是若要壓縮備份檔，仍須搭配 `tar` 進行備份。

### script 實作方法
全部使用 shell script 完成。利用 getopt 來得到使用者輸入的參數，再由這些參數決定接下來的行為。讀取 config file 部份，先用 `sed -e 's/#.*//g' -e '/^\s*$/d' "$file"` 將檔案中的註解（『#』以後的字串）濾掉再做處理。餘下備份及還原則透過 `rsync` 完成。

### 遇到的困難與改善方法
#### 使用者輸入的資料夾名稱不一定會包含『/』(slash)
利用 shell script 的字串處理來去除字串字尾的『/』(slash)

~~~
#!/bin/sh

test_no_slash=test
test_end_slash=test/
test_middle_slash=t/est

echo ${test_no_slash%/}       # test
echo ${test_end_slash%/}      # test
echo ${test_middle_slash%/}   # t/est
~~~
#### 實作 incremental backup 時，對於每次都要檢查每一份備份資料夾覺得缺乏效率
利用 `--link-dest=DIR` 實現。當 `rsync` 運作時檢查要複製的檔案是否和 DIR 裡的一樣。如果和 DIR 的一樣則不複製，改成 hardlink 到 DIR 的該擋，如此可避免重複複製檔案。

### Project 實作結果與截圖
下圖為 `backup.sh` 的使用說明：
![](https://i.imgur.com/mqEoaeB.png)
我們試著用 config file 來做 incremental backup 看看：在 15:15 前修改 `crontab` ，讓它每分鐘把 `/home/nasa2016/hsinmu_pic` 內的資料備份到 server (10.0.2.7) 端，然後在 15:16 時加一個 `hsinmu_3.jpg` 看看。下圖左側為 15:17 後 client 端欲備份資料夾中的檔案，右側為 server 端備份後的樹狀圖，分別在 15:15 、 15:16 、 15:17 進行了一次備份，其中 15:17 分時多了一個 `hsinmu_3.jpg` ，正是16分時所新加的檔案。
![](https://i.imgur.com/DuNz2Y9.png)
接著為了證明它確實是 incremental backup ，我們調出了 `hsinmu_1.jpg` 的 inode number，發現確實在不同備份資料夾中的 `hsinmu_1.jpg` ，它們的 inode number 皆是同一個 (269917) (如下圖右下)，證明它並沒有重新 full backup 一份，而是如上一節所提到的，用 hardlink 的方式做個連結，如此在下次備份時，只要和上一個 timestamp 的資料夾做比較即可。
而下圖左側為 config file 的設定，右上則為 `crontab` 的設定。
![](https://i.imgur.com/myRXKPl.png)



### 未來方向
以下列出可能可以新增的功能與方向：
* 新增更多使用者選項，如 `--verbose` 、 `--dryrun`
* 壓縮、加密備份檔
* 刪除不必要/過舊的備份檔

### 參考資料

* http://www.tldp.org/LDP/abs/html/string-manipulation.html
* http://linux.vbird.org/linux_basic/0430cron.php
* http://linux.die.net/man/1/rsync
* https://en.wikipedia.org/wiki/Rsync