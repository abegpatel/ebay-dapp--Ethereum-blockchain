const Ecommerceproduct = artifacts.require('EcommerceStore');
module.exports = function(deployer) {
  deployer.deploy(Ecommerceproduct);
  
};
