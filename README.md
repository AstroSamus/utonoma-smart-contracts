# Utonoma

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Utonoma is a social network like no other. It works on the blockchain and allows content creators to earn cryptocurrencies for each like. Only one condition: if a content has too many dislikes it will be removed from the platform. This small change in the rules allows content moderation in a democratic and decentralized way, contributing to the creation of the freer internet we all dream of.

This github repository covers only the “back-end” of the project, the smart contract that works on the blockchain and has all the business rules written. This smart contract allows users to upload content by classifying it into any of the following categories:
<ul>
  <li>🎧 audios</li>
  <li>🎶 music</li>
  <li>🎙️ podcasts</li>
  <li>🎤 audioLivestreams</li>
  <li>📹 videos</li>
  <li>🎬 shortVideos</li>
  <li>🎥 movies</li>  
  <li>📡 videoLivestreams</li>
  <li>💬 comments</li>
  <li>📝 blogs</li>
  <li>📚 books</li>  
  <li>🖼️ images</li>
  <li>🌀 animations</li>
  <li>🎮 videoGames</li>
  <li>📱 apps</li>
</ul>

The smart contract, being public on the blockchain, allows you – yeah, you! – to create your own social network with all the functionalities that the system offers (user names, content libraries, awards, punishments, etc.) by just calling the methods from the deployed contract.

## White Paper
English: http://utonoma.com/paper/utonoma_en.pdf

Spanish (original): http://utonoma.com/paper/utonoma_es.pdf 

## License
Dual-licensed: MIT, Apache Software License v2

## 🚀 Quick Start

Just clone the project and open it with Remix IDE. To run the unit testing suite you have to install the [Remix Unit Test plugin](https://remix-ide.readthedocs.io/en/latest/unittesting.html).
Remember that the main contract that must be deployed is Utonoma.sol.

## Contributing

Feel free to fork the repository and submitting a pull request. Also, you can open an [issue](https://github.com/AstroSamus/utonoma/issues) to suggest a feature or report a bug.

Before doing your contributions, we suggest you take a look at the [user stories](https://github.com/users/AstroSamus/projects/2), to be more familiar with all the functionalities and design decisions that were made during the development process.

## Authors

* Gerardo Pedrizco - Initial work - https://github.com/MarxMad
* Adrián Sequeira - Initial work - https://github.com/AstroSamus

![image](https://blog.utonoma.com/wp-content/uploads/utonoma1x.jpg)

Important note: to run the testing suite you should type: forge test --ffi