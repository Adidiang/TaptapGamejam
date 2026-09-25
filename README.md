# TaptapGamejam · 余夜

Godot 4.7 的 21 点肉鸽游戏原型。游戏项目位于 [NightTable](NightTable/README.md)，规则与设计取舍见 [玩法说明](NightTable/docs/玩法实现v0.2.md)。

最新设计依据：[本地游戏策划案](NightTable/docs/游戏策划案.md)。数字牌、功能牌与负荷机制已接入局内，临时卡牌配置和扩展入口见 [局内对战 v0.3](NightTable/docs/局内对战v0.3.md)。

## 运行

使用 Godot 4.7 打开 `NightTable/project.godot`，按 F5。项目使用 GDScript，不需要 .NET SDK。

本机可直接双击 `NightTable/启动游戏.cmd`；该快捷方式依赖仓库旁的本地引擎目录。Godot 引擎程序、导入缓存、生成截图和导出包不上传到 Git。

## 上传更新

在仓库目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\sync-git.ps1 -Message "说明这次修改"
```

也可以让助手调用脚本。省略 Message 时使用带时间的默认提交说明。仅检查待提交内容：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\sync-git.ps1 -CheckOnly
```

脚本固定使用本仓库的 origin/main，先获取远端状态，再提交所有未忽略的增删改并推送。远端包含本地没有的提交、存在冲突、分支或地址不符时停止；不会强制覆盖或自动合并。推送失败时保留本地提交，可解决网络或登录问题后再次运行。

首次在其他电脑使用时需要安装 Git、设置提交身份，并通过 Git 凭据管理器登录有仓库写权限的 GitHub 账号。凭据不要写入脚本或提交到仓库。
