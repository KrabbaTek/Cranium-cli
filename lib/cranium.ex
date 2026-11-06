defmodule Cranium do
  # works for development but needs to be changed for production
  @base_url "http://127.0.0.1:3000/api/"
  @fun_facts ["The Swedish parliament is called riksdag and it has 349 members in a single chamber.",
  "Sweden is so long that it's possible for northern parts to have snow on the ground despite the south being in bloom.",
  "In Norway, the lake Hornindalsvatnet is the deepest lake in Europe.",
  "Located in Norway, Sognefjorden is the world's second deepest fjord.",
  "Denmark is one of the happiest countries in the world according to the UN world happiness report.",
  "The Danish flag “Dannebrog” is the world's oldest flag, being first acknowledged in 1219.",
  "Around 75% of Finland's surface area is covered with forests, and Finland is home to the world's largest archipelago.",
  "In Helsinki, 11 out of 12 lost wallets are returned to their owners."]

  # /Users/reeceturner/.kscript/libs
  @packages_directory "~/.kscript/libs" |> Path.expand

  defp query endpoint do
    uri = @base_url <> endpoint
    case Req.get(uri) do
      # package not found
      {:ok, %{status: 404}} ->
        IO.puts "A package with that name doesn't exist."
        System.halt 0
      {:ok, response} -> response.body
      {:error, _reason} -> IO.puts "Something went wrong while contacting the server."; System.halt
    end
  end

  # quits the program unless user types "y" or "Y"
  defp confirm message do
    case IO.gets(message <> " [Y/n] ") |> String.trim |> String.downcase do
      "y" -> true
      _ -> System.halt
    end
  end

  # no package was provided
  def fetch([]) do
    IO.puts "You didn't share a package — what package would you like to install?"
    System.halt
  end

  # install a package
  def fetch([package]) do
    body = query("install/#{package}")

    confirm "Are you sure you want to install #{package}?"

    tarball = body["tarball"]

    download_and_extract(tarball, package)

    IO.puts "Successfully installed #{package}."
    IO.puts "If you ever want to delete it, run `cranium annihilate #{package}`."
  end

  defp download_and_extract(url, name) do
    # download the raw tarball bytes from the server
    %{body: tarball} = Req.get! url

    # where the package will live after extraction
    dest = Path.join @packages_directory, name

    # write the tarball to a temp file so tar can read it
    tmp = Path.join(System.tmp_dir!(), "#{name}.tar.gz")
    File.write! tmp, tarball

    # create the destination directory if it doesn't exist
    File.mkdir_p! dest

    # extract the tarball into the destination directory
    System.cmd("tar", ["-xzf", tmp, "-C", dest])

    # clean up the temp file
    File.rm! tmp
  end


  # displays the top five packages for today (24 hours)
  def serve_omakase do
    %{
      "name" => name,
      "description" => description,
      "github_url" => github_url
      } = query("omakase")

    IO.puts "Here's what's on the menu for today:"
    IO.puts "Name:\n#{name}\n"

    IO.puts "Description:\n#{description}\n"

    IO.puts "Link to the GitHub repo:\n#{github_url}"
  end

  # displays a random package
  def pick_random_package do
    %{
      "name" => name,
      "description" => description,
      "github_url" => github_url
      } = query("packages/random")

      # change the wording of this
      IO.puts("Random package: #{name}, #{description}, #{github_url}")
  end

  # verify the timeframe used in the wipe command.
  # It must follow this syntax:
  defp verify_timeframe(timeframe) do
    case String.match?(timeframe, ~r/(older|younger) than (\d) day(s)?/) do
      false ->
        IO.puts "Invalid timeframe given: #{timeframe}. It must follow this syntax: older/younger than x days"
        System.halt
      _ -> true
    end
  end

  defp parse_timeframe(timeframe) do
  [_, direction, days] = Regex.run(~r/(older|younger) than (\d+) day(s)?/, timeframe)
  days = String.to_integer(days)
  cutoff = NaiveDateTime.utc_now() |> NaiveDateTime.add(-days, :day)

  case direction do
    "older"   -> {cutoff, :older}
    "younger" -> {cutoff, :younger}
  end
end

  # delete all packages
  def delete_packages([]) do
    files = case File.ls(@packages_directory) do
      {:ok, files} -> files
      {:error, _reason} -> IO.puts "Failed to read the libs/ directory."; System.halt(1)
    end

    # no packages to delete
    if Enum.empty? files do
      IO.puts "There are no files to delete."; System.halt
    end

    # confirm deletion
    case IO.gets("Are you sure you want to delete all of your packages? [Y/n]") |> String.trim do
      "Y" -> case IO.gets("Are you super duper cereal right now?") |> String.trim |> String.downcase do
        "y"    -> :ok
        "yes"  -> :ok
        "yeah" -> :ok
        _ -> System.halt
      end
      _ -> System.halt
    end


    Enum.each(files, fn file ->
       File.rm_rf!(Path.join(@packages_directory, file))
    end)

    IO.puts "Successfully destroyed all installed packages."
  end

  # delete a singular package
  def delete_packages([name]) do
    path = Path.join @packages_directory, name

    confirm "Are you sure you want to delete #{name}?"

    case File.rm_rf(path) do
      {:ok, []} ->
        IO.puts "You wanted to delete #{name} but it doesn't exist; you don't have it installed."
        System.halt
      {:ok, _} ->
        IO.puts "Successfully eradicated #{name}."
      {:error, reason, _} ->
        IO.puts "Failed to delete #{name}: #{reason}"
        System.halt(1)
    end
  end

  # delete all packages within a timeframe
  def delete_packages(raw_timeframe) do
    timeframe = Enum.join(raw_timeframe, " ")

    verify_timeframe(timeframe)

    {cutoff, direction} = parse_timeframe(timeframe)

    all_packages =
      case File.ls(@packages_directory) do
        {:ok, files} -> files
        {:error, _reason} ->
          IO.puts "Failed to read the libs/ directory."
          System.halt 1
      end

    if Enum.empty? all_packages do
      IO.puts "You don't have any packages installed."
      System.halt
    end

    found_packages =
      Path.wildcard(Path.join @packages_directory, "*")
      |> Enum.filter(fn path ->
        mtime = File.stat!(path).mtime |> NaiveDateTime.from_erl!
        case direction do
          :older   -> NaiveDateTime.compare(mtime, cutoff) == :lt
          :younger -> NaiveDateTime.compare(mtime, cutoff) == :gt
        end
      end)

    if Enum.empty? found_packages do
      IO.puts "No packages exist within those constraints: #{timeframe}"
      System.halt
    end

    case IO.gets("This will delete #{length(found_packages)} package(s). Are you sure? [Y/n] — type 's' to list the packages. ")
        |> String.trim |> String.downcase do
      "s" ->
        IO.puts "The following files would be deleted:"
        Enum.each(found_packages, fn path ->
          # cleans up the path — remove the leading /Users/reeceturner/.kscript/libs
          IO.puts "#{Path.basename(path)}"
        end)

        confirm "Do you want to proceed?"
      "y" -> :ok
      _   -> System.halt
    end

    Enum.each(found_packages, fn path ->
      case File.rm_rf(path) do
        {:ok, _} -> IO.puts("Deleted: #{path}")
        {:error, reason, file} -> IO.puts("Failed to delete #{file}: #{reason}")
      end
    end)

    IO.puts "Done. #{length(found_packages)} package(s) deleted."
  end

  # displays a random fun fact
  def provide_fun_fact do
    Enum.random @fun_facts
    |> IO.puts
  end

  # no project was provided
  def clone_into([]) do
    IO.puts "You didn't share a package — what package would you like to clone into?"
    System.halt
  end

  # git clone a package (doesn't install the package)
  def clone_into([project | _rest]) do
    %{"github_url" => github_url} = query("packages/clone/#{project}")

    IO.puts "Cloning #{project}."

    # safely git clone
    case System.cmd("git", ["clone", github_url]) do
      {_, 0} -> IO.puts "Remember to `cd` into #{project}!" # command runs fine
      {output, _} -> IO.puts "Failed to clone: #{output}"
    end
  end

  # displays all packages you have installed
  def your_packages do
    files = case File.ls(@packages_directory) do
      {:ok, files} -> files
      {:error, _reason} -> IO.puts "Failed to read the libs/ directory."
    end

    if Enum.empty? files do
      IO.puts "You have no packages installed."
    else
      IO.puts "All packages:"
      Enum.each(files, fn file ->
        IO.puts "#{file}"
      end)

      IO.puts "\nIn Total, you have #{length(files)} packages."
    end
  end

  # no package was provided
  def search_for([]) do
    IO.puts "Please specify a package to search for."; System.halt
  end

  # search for a package
  def search_for [package] do
    matches = query "packages/search/#{package}"

    # IO.puts "Body:"

    # IO.inspect matches

    # this shouldn't ever be true considering the server returns a 404 when no matches are found
    if Enum.empty? matches do
      IO.puts "No packages with that name exist"; System.halt
    end

    if length(matches) > 1 do
      IO.puts "Found packages:"
    else
      IO.puts "Found package:"
    end

    # print each found package
    Enum.each(matches, fn match ->
      %{
        "name" => name,
        "description" => description,
        "github_url" => github_url
      } = match

      IO.puts name <> "\n\n"
      IO.puts description <> "\n\n"
      IO.puts "Check out the project on GitHub:\n\n" <> github_url
    end)
  end

  # just for clarity, really.
  # somebody might not be aware of Cranium's conventions and it's best to steer them in the right direction
  # instead of just saying "unknown command"
  def print_upload_message do
    "You cannot upload libraries through the Cranium CLI. To upload a library, please visit the Cranium website."
    |> IO.puts
  end

  def print_help_message do
    "Help placeholder"
    |> IO.puts
  end


  defp levenshtein(s, t) do
    s = String.graphemes(s)
    t = String.graphemes(t)

    distance(s, t)
  end

  defp distance([], t), do: length(t)
  defp distance(s, []), do: length(s)
  defp distance([h | s], [h | t]), do: distance(s, t)
  defp distance([_ | s] = s_full, [_ | t] = t_full) do
    1 + Enum.min([
      distance(s, t_full), # deletion
      distance(s_full, t), # insertion
      distance(s, t)       # substitution
    ])
  end

  # dispatches a command to the corresponding function
  defp dispatch(command, rest) do
    case command do
      cmd when cmd in ~w[ fetch install retrieve get grab g ] ->
         fetch(rest)
      cmd when cmd in ~w[ omakase menu ] ->
        serve_omakase()
      cmd when cmd in ~w[ random lottery propose ] ->
        pick_random_package()
      cmd when cmd in ~w[ massacre annihilate slaughter remove delete wipe ] ->
        delete_packages(rest)
      cmd when cmd in ~w[ my-packages packages list ] ->
        your_packages()
      cmd when cmd in ~w[ publish push upload ] ->
        print_upload_message()
      cmd when cmd in ~w[ tear-apart clone ] ->
        clone_into(rest)
      cmd when cmd in ~w[ find locate search lookup ] ->
        search_for(rest)
      cmd when cmd in ~w[ help h ] ->
        print_help_message()
      "fun-fact" -> provide_fun_fact()
      _ ->
        # there is genuinely zero reason why this would happen
        IO.puts "That's not a recognized command. Type 'help' for a list of the commands."
      end
    end

  def main([command | rest]) do
    if !File.dir?(@packages_directory) do
      IO.puts "Something went wrong: you are missing the packages directory: ~/.kscript/libs/"
      IO.puts "Try running `mkdir ~/.kscript/libs`."
      System.halt
    end

    # I excluded the publish commands because we would infer the command just to tell them it's not a command—
    # sounds redundant to me.
    commands = ~w[
    fetch install retrieve get grab g
    omakase menu
    random lottery propose
    massacre annihilate slaughter remove delete wipe
    my-packages packages list
    tear-apart clone
    find locate search lookup
    h help
    ]

    if command in commands do
      dispatch(command, rest)
    else
      # find what command is closest to the user's input
      closest = Enum.min_by(commands, &levenshtein(&1, command))

      if levenshtein(closest, command) <= 2 do
        case IO.gets("Unknown command '#{command}'. Did you mean '#{closest}'? [Y/n] ") |> String.trim |> String.downcase do
          "y" ->
            # call the closest command
            dispatch(closest, rest)
          _ ->
            System.halt
        end
      else
        IO.puts "That's not a recognized command. Type 'help' for a list of the commands."
      end
    end
  end

  # no command was passed
  def main([]) do
    "Please provide a command. Type 'help' for a list of commands."
    |> IO.puts
  end
end
