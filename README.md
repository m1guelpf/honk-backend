# A backend for Honk

Honk was [a real-time messaging app](https://www.honk.me/). It let you really feel connected with your friends, even when they weren't close, and is probably the most beautiful app I've ever used.

In November 2023, [Honk was shut down](https://www.honk.me/sunset) and removed from the App Store. Some of its designed lived on as Family, a web3 wallet, which is now also being shut down.

Some weeks ago, I found an old iPad that still had the app on it, and managed to extract a clean copy and re-install it on my phone. It launched, but of course couldn't work without its server.

So, I'm trying to build my own Honk server, with some reverse-engineering of the app and a lot of trial and error.

~ Miguel

## Some questions you might have

### How exactly are you doing this?

I've patched the app to talk to `localhost`. When I launch it, I see the requests the app tries to make, and try to figure out what those endpoints used to do and the kind of response the app expects.

Often I can look through a disassembly of the app's binary (shotout [Binary Ninja](https://binary.ninja/) and get a general idea of what fields it expects. The rest of the time, I try something, look at the error logs, and change stuff until it no longer errors.

### How far have you gotten?

Some things that work: Creating an account, the onboarding, contact matching, account settings, phone number verification
What doesn't work yet: everything else

### Does that mean I'll be able to use Honk again with my friends?

Well it definitely makes it easier than before, but probably not (without going through a lot of trouble to set things up first, at least).

The main trouble is, Apple requires apps to be signed, If you want notifications/auth to work, they need to be signed by the same person running the backend. Distributing a re-signed app made by someone else goes against Apple's Developer Terms, and may also constitute copyright infringement.

Once more of the things above work (mainly the chat part), I'll open-source the scripts I use to patch the app, and others who have extracted a copy of the app should be able to patch it and run it against their own server.

### Why is the server written in Swift?

I love Swift's language features. It lets you write really beautiful abstractions while providing strict guarantees around thread-safety and typing in general. I've played with Vapor, but had never done a full web project with Swift, and this seemed like a good chance.

Note that the server still compiles down to a cross-platform binary, so it can be ran on Linux. I'll add a Dockerfile to make it super easy to deploy soon-ish

## Use of AI

While the source for this project is completely hand-written, I use Codex to review commits before pushing and Claude to get a second opinion while digging through the binary.

I like to write code, and am having lots of fun deeply exploring how an app I loved used to work. If you choose to contribute, please disclose any uses of AI.

## License

This project is licensed under the MIT License. See the [License file](LICENSE) for more information.
