# Writing-Focus-Editor

[English](./README-en.md)

[中文](./README.md)

## Why This Project

I found the notepad app that came with my Android phone difficult to use, I won't mention the phone brand here

First, it lacks a batch export feature. With this app, you can connect your phone to a computer via USB and access all your notes in Android/data/com.example.learn/files/WHNotesApp.

Second, the infinite scroll design. Since it's not a commercial application, why arrange the notes in a feed-style layout? It's easy to get lost in the endless scrolling. This app uses pagination to arrange notes, with 8 notes per page, so you can see exactly how many notes you have at a glance.

Third, when I open a note, the cursor is at the very top, forcing me to manually scroll to the bottom to begin editing. This might be fine for reading, but it wastes my time. This app, however, jumps immediately to the end of the file and opens the keyboard upon opening a note. To me, a mobile note application is positioned more as an editor than a notepad.

Fourth, the large space taken up by shortcuts. The minimum size for a shortcut to a note on my phone's default app is four grid squares. I frequently edit 3-4 notes, and this takes up too much space, preventing me from putting all my frequently used apps on a single home screen. This app only requires one grid square for a note shortcut.

These four points were enough to convince me to write such an application. I looked into ways to develop Android software and finally decided on Flutter. My project name is "learn" because I originally created it to learn Flutter, and then I was too lazy to change it, time is paramount, a concept you can probably sense from the four points above.

## Files I Modified

This is my first Flutter project, and I'm not sure how to make it easy for others to reproduce or modify. However, the project is small and simple, so I've listed the new and edited files. If you plan to continue development, you should understand what I mean—though given how advanced AI is now, it might be better to start from scratch:

./android/app/src/main/kotlin/com/example/learn/MainActivity.kt

./android/app/src/main/AndroidManifest.xml

./lib/main.dart

./lib/note_page.dart

## How to Use

Download the APK and install it. The only thing to note is that to create a desktop shortcut for a note, you must first grant the application permission to create home screen shortcuts.

Also, this app does not have a delete function, as it is unnecessary.
