# zsh

[oh-my-zsh](https://ohmyz.sh/)

  ```shell
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  ```

## Enable Any Oh My Zsh Plugins

Oh My Zsh comes with a ton of plugins you can take advantage of. Here is the [wiki](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins) page.

Open your ``` ~/.zshrc ``` file via Terminal

```shell
open ~/.zshrc
```

Find and edit the plugins section to add the ones you want

```shell
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git brew ruby osx)
```

## Set the Oh My Zsh Theme

Open your ``` ~/.zshrc ``` file via Terminal

```shell
open ~/.zshrc
```

Modify the theme. You can find a list of the themes [here](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes.)

Make sure to save and close the file after editing. You may have to quit and reopen iTerm2 for the theme to take effect.
