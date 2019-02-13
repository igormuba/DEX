let exchange = artifacts.require("exchange");
let erc20 = artifacts.require("erc20");

module.exports = function(deployer) {
  deployer.deploy(exchange);
  deployer.deploy(erc20);
};
