# Writing-Focus-Editor

[English](./README.md)

[中文](./README-zh.md)

## why this project

我用安卓自带的记事本的时候有些不顺手, 在这里不提我用的手机品牌

第一, 无法批量导出, 这个App你可以用USB连接电脑, 然后在Android/data/com.example.learn/files/WHNotesApp获取所有你的笔记

第二, 下滑的设计, 明明不是商业应用, 为什么还要使用信息流的排布来排列笔记, 容易让人迷失在下滑当中? 这个App使用分页的方式排列笔记, 一页8个笔记, 一个有多少个笔记一目了然

第三, 我打开一个笔记结果在第一行, 要我手动滑到最下方编辑, 这也许很适合阅读, 但是对我而言是浪费时间, 这个App则是一打开笔记就跳到文件末尾并打开键盘. 所以我对于手机的记事本的定位更像是editor而不是notepad

第四, 快捷方式的占用面积大, 我手机自带的记事本要把一个笔记放到桌面上最小要占用四格, 我有3-4个笔记要经常编辑, 这样一来无法满足我把所有常用App放到一页的需求, 而这个App只需要一格

以上四点足以说服我写一个这样的程序, 所以我查找了一下关于开发安卓软件的方式, 最后决定使用flutter, 我的项目名是learn, 因为我原本是创建来学习flutter的, 后来也懒得切换了, 时间是最重要的, 你应该能从以上四点感受到一些东西.

## files I modify

这是我的第一个flutter项目, 我不知道该如何让别人轻易的复现和改造, 不过这个项目很小很简单, 所以我把新建的以及编辑过的文件列出来, 如果你要接着开发你应该能懂我的意思, 不过现在AI很发达, 也许你从头写一个可能比较好:

./android/app/src/main/kotlin/com/example/learn/MainActivity.kt

./android/app/src/main/AndroidManifest.xml

./lib/main.dart

./lib/note_page.dart

## how to use

下载APK, 然后安装, 唯一要注意的是, 如果要创建一个笔记的快捷方式那么需要先授权让应用可以创建桌面快捷方式

以及这个App没有删除功能, 因为没有必要