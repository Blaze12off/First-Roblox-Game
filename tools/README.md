# Локальные инструменты

`tests/RunLocal.ps1` использует официальный Luau CLI версии 0.741.
Скачанный архив и исполняемые файлы исключены через `.gitignore`.

Для запуска тестов на другом компьютере скачайте `luau-windows.zip` из
[релиза Luau 0.741](https://github.com/luau-lang/luau/releases/tag/0.741)
и распакуйте его в `tools/luau-0.741/`. Затем из корня проекта выполните:

```powershell
.\tests\RunLocal.ps1
```
