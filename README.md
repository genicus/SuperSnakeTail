# SuperSnakeTail
You might know the log reading tool "tail" from the unix and unix-like world. It has a feature to follow the file if you add the parameter f.

At work we use an alternative (with a GUI) for Windows: SnakeTail. It's a nice tool which includes some neat features, like highlighting of specific lines if a certain string is found in those lines.

The thing is, like with tail on other platforms, it doesn't really allow you to filter out things you don't want to see. In the *nix world, you are able to filter out the lines you don't need by using grep. With SnakeTail you can't.

That's where this PowerShell script comes into play.

The script takes a logfile, and feeds each line to an algorithm. By calling the script with parameters, you can manipulate the output of algorithm. Everything is documented in the script as per PowerShell standard.

And it's without a GUI. So it works decently on WS Core.

