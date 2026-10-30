# Cranium

Cranium is a beautiful and opinionated package manager for [KrabbaScript](https://github.com/KrabbaTek/krabbascript).
It removes a lot of the worst parts from package managers like RubyGems;
for example, no directory structures are enforced and no manifest files are required.

To top it all off, Cranium believes there is more than one way to do packages. 
We don't have to conform to the false (and painful) standards set by Cranium's forefathers;
we don't have to hate the user; we don't have to make their lives painful; Cranium serves you, not the other way around.
Cranium will almost never tell you what you can't do — it will smile and conform to your will.

If you like the sound of that, then keep reading. Otherwise, Cranium isn't for you—
if you're looking for pain and a bad user experience, might I suggest Golang?

# Commands

Cranium has a pretty hefty list of commands. I'll start out with the basic ones.
At the end, I'll go over the aliases for these commands.


## Install
  `cranium install suomi-lib`

## Delete
  `cranium delete suomi-lib`

Beyond the basics, Cranium offers some nice commands. Some are just for fun, like `omakase`, but Cranium also provides a wide variety of sharp knives.
Here are the rest:

## Omakase
This provides a list of the top five most popular packages for today (refreshes every 24 hours)

`cranium omakase`

## Wipe
This will delete every package you've ever installed with Cranium:

`cranium wipe`

You can also pass a timeframe using this syntax: `older/younger than (x) days`:

`cranium wipe older than 3 days`

Or,

`cranium wipe younger than 4 days`

## Tear apart
This is used to inspect the source code of a package. More specifically, it git clones into the project.

`cranium tear-apart suomi-lib`

You do not need to have the package installed to do this, and it will not install the package.

## list
Lists all your packages:

`cranium list`

Like with `wipe`, you can pass a timeframe argument to be more specific:

`cranium list older than 5 days`

This will only list packages you've had installed for more than 5 days.

## Fun fact
And to top it all off, you can use fun-fact to get a random nordic fun fact:
  cranium fun-fact

Here's a taste:

"Located in Norway, Sognefjorden is the world’s second deepest fjord."

# TIMTOWTDI

Cranium is a firm believer that there is more than one way to do it. 
For almost every command, there are multiple aliases you can use. 
Here are all of them: 

## install:
	•	fetch
	•	retrieve
	•	get
	•	grab
	•	g

## omakase
	•	menu

## massacre
	•	annihilate
	•	wipe

## delete
	•	slay
	•	eradicate
	•	remove
	•	execute

## list
	•	my-packages
	•	packages

Anything not mentioned above does not have any aliases.

# What's the catch?

Naturally, all the things I said above have some catches — everything has a tradeoff.

Cranium does not enforce directory structures, but this means you have to be a bit more explicit.
I don't see this as a problem, since it allows you to be more obvious and aware of what's happening.
For example, when uploading a library (in the website), you'll have to share a name, description, tarball, and GitHub URL yourself.

That process saves you from having to write a config file and staining your codebase with Cranium, 
which is deeply more important.

I'm a firm believer in the separation of tool and code — this same principle can be seen in [Lieksa](https://github.com/Centurion774477/Lieksa),
a language-agnostic documentation generator that requires no changes to your codebase.

Cranium also doesn't handle dependencies — not one bit. This makes it a lot easier to reason about packages, but it comes with glaring trade-offs.
For example: you cannot use complex libraries, which is fine, given this is KrabbaScript and the library scene is quite sparse at the moment.

That's basically it. Here's the thing: most of the pain in RubyGems is for no reason; it's not because the solution is hard or that there are tradeoffs—
people just don't care about the user's experience.

We've been tricked to believe that an easy-to-use tool is bad because it's such a rare sight, but this couldn't be further from the truth.
Cranium has tradeoffs, yes, but most of the features come with no real cost.

# What can't you do?

Notice how I said Cranium *almost* never tells you what you can't do?
Cranium has to put it's foot down somewhere, so like even the most merciful of people, it's lenience has to end somewhere.

One of the most notable principles Cranium rejects is uploading packages through the CLI.
I believe uploading packages through the CLI is wrong because it requires much more effort — authentication, repeating yourself, etc.

So, just like the above example, the only times you can't do something is when there's a clear and correct choice — this is the opinionated part from before.

# Ending

This is just the CLI, but Cranium can only truly be enjoyed when you've used the website.
