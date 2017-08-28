ExUnit.start(exclude: [:skip])

"./test/support"
|> File.ls!
|> Enum.each(&Code.require_file("support/#{&1}", __DIR__))
