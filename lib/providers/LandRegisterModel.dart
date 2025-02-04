import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:land_registration/constant/constants.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
//import 'package:web_socket_channel/io.dart';

class LandRegisterModel extends ChangeNotifier {
  bool isLoading = true;
  final String _rpcUrl =
      "https://rpc-mumbai.maticvigil.com/v1/a5be973518c173bacd9be16a6314dd08b6abcd23"; //"http://127.0.0.1:7545"
  //final String _wsUrl = "wss://rpc-mumbai.maticvigil.com/ws/v1/a5be973518c173bacd9be16a6314dd08b6abcd23";

  String _privateKey = privateKey;

  String contractAddress = "0x5Fa4972AB37701FA32907E79b46DDD436bd73B05";

  late Web3Client _client;
  late String _abiCode;
  late Credentials _credentials;
  late EthereumAddress _contractAddress;
  late EthereumAddress _ownAddress;
  late DeployedContract _contract;
  late ContractFunction _addLandInspector;
  late ContractFunction _registerUser;
  late ContractFunction _isLandInspector;
  late ContractFunction _isContractOwner;
  late ContractFunction _isUserRegistered;
  late ContractFunction _makePaymentTest;
  late ContractFunction _allUsers;
  late ContractFunction _userInfo;
  late ContractFunction _verifyUser;
  late ContractFunction _userCount;
  late ContractFunction _addLand;
  late ContractFunction _myAllLands;
  late ContractFunction _landInfo;
  late ContractFunction _allLandList,
      _verifyLand,
      _makeforSell,
      _sendRequestToBuy,
      _myReceivedRequest,
      _mySentRequest,
      _requestInfo;
  late ContractFunction _landCount;
  late ContractFunction _acceptRequest, _rejectRequest;
  late ContractFunction _landPrice;
  late ContractFunction _makePayment;
  late ContractFunction _paymentDoneList;
  late ContractFunction _transferOwner;

  LandRegisterModel() {
    //initiateSetup();
  }

  Future<void> initiateSetup() async {
    _privateKey = privateKey;
    // _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
    //   return IOWebSocketChannel.connect(_wsUrl).cast<String>();
    // });
    _client = Web3Client(_rpcUrl, Client());

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/contracts/Land.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress = //EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
        EthereumAddress.fromHex(
            contractAddress); //EthereumAddress.fromHex("0xD6af79CcaaCc6e1d747909d7580630aFc69Ff0B8"); //
    //print(_contractAddress);
  }

  Future<void> getCredentials() async {
    print(_privateKey);

    _credentials = EthPrivateKey.fromHex(
        _privateKey); //await _client.credentialsFromPrivateKey(_privateKey);
    _ownAddress = await _credentials.extractAddress();
    print(_ownAddress.toString());
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(
        ContractAbi.fromJson(_abiCode, "Land"), _contractAddress);

    _addLandInspector = _contract.function("addLandInspector");
    _registerUser = _contract.function("registerUser");
    _isLandInspector = _contract.function("isLandInspector");
    _isContractOwner = _contract.function("isContractOwner");
    _isUserRegistered = _contract.function("isUserRegistered");
    _makePaymentTest = _contract.function("makePaymentTestFun");
    _allUsers = _contract.function("ReturnAllUserList");
    _userInfo = _contract.function("UserMapping");
    _verifyUser = _contract.function("verifyUser");
    _userCount = _contract.function("userCount");
    _addLand = _contract.function("addLand");
    _myAllLands = _contract.function("myAllLands");
    _landInfo = _contract.function("lands");
    _allLandList = _contract.function("ReturnAllLandList");
    _verifyLand = _contract.function("verifyLand");
    _makeforSell = _contract.function("makeItforSell");
    _sendRequestToBuy = _contract.function("requestforBuy");
    _myReceivedRequest = _contract.function("myReceivedLandRequests");
    _mySentRequest = _contract.function("mySentLandRequests");
    _requestInfo = _contract.function("LandRequestMapping");
    _landCount = _contract.function("landsCount");
    _acceptRequest = _contract.function("acceptRequest");
    _rejectRequest = _contract.function("rejectRequest");
    _landPrice = _contract.function("landPrice");
    _makePayment = _contract.function("makePayment");
    _paymentDoneList = _contract.function("returnPaymentDoneList");
    _transferOwner = _contract.function("transferOwnership");
  }

  makePaymentTestFun(dynamic price) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _makePaymentTest,
            parameters: [
              EthereumAddress.fromHex(
                  '0x0d1E9c89A88A3BcAB4cECb31686b132e1727E379')
            ],
            value: EtherAmount.fromUnitAndValue(
                EtherUnit.wei, (price * pow(10, 18)).toString())),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  transferOwnership(dynamic reqId) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _transferOwner,
          parameters: [reqId],
        ),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<List<dynamic>> paymentDoneList() async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _paymentDoneList,
        params: []);
    //print(val);
    return val[0];
  }

  makePayment(dynamic reqId, dynamic price) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _makePayment,
            parameters: [reqId],
            value: EtherAmount.fromUnitAndValue(
                EtherUnit.wei, (price * pow(10, 18)).toString())),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<dynamic> landPrice(dynamic landId) async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _landPrice,
        params: [landId]);
    //print(val);
    return val[0];
  }

  acceptRequest(dynamic reqId) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _acceptRequest,
            parameters: [
              reqId,
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  rejectRequest(dynamic reqId) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _rejectRequest,
            parameters: [
              reqId,
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<List<dynamic>> requestInfo(dynamic requestId) async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _requestInfo,
        params: [requestId]);
    //print(val);
    return val;
  }

  Future<List<dynamic>> mySentRequest() async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _mySentRequest,
        params: []);
    //print(val);
    return val[0];
  }

  Future<List<dynamic>> myReceivedRequest() async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _myReceivedRequest,
        params: []);
    //print(val);
    return val[0];
  }

  sendRequestToBuy(dynamic landId) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _sendRequestToBuy,
            parameters: [
              landId,
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  makeForSell(dynamic id) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _makeforSell,
            parameters: [
              id,
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<List<dynamic>> landInfo(dynamic id) async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _landInfo,
        params: [id]);
    //print(val);
    return val;
  }

  verifyLand(dynamic id) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _verifyLand,
            parameters: [
              id,
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<List<dynamic>> allLandList() async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _allLandList,
        params: []);
    //print(val);
    return val[0];
  }

  isContractOwner(String address) async {
    final val = await _client.call(
        sender: _ownAddress,
        contract: _contract,
        function: _isContractOwner,
        params: [_ownAddress]);
    print(val);
    return val[0];
  }

  Future<List<dynamic>> myAllLands() async {
    final val = await _client.call(
        contract: _contract, function: _myAllLands, params: [_ownAddress]);
    print(val);
    return val[0];
  }

  addLand(String area, String city, String state, String landPrice, String PID,
      String surveyNo, String docu) async {
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _addLand,
            parameters: [
              BigInt.parse(area),
              city,
              state,
              BigInt.parse(landPrice),
              BigInt.parse(PID),
              BigInt.parse(surveyNo),
              docu
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<dynamic> landCount() async {
    notifyListeners();
    final val = await _client
        .call(contract: _contract, function: _landCount, params: []);
    print(val);
    return val[0];
  }

  Future<dynamic> userCount() async {
    notifyListeners();
    final val = await _client
        .call(contract: _contract, function: _userCount, params: []);
    print(val);
    return val[0];
  }

  Future<List<dynamic>> allUsers() async {
    notifyListeners();
    final val = await _client
        .call(contract: _contract, function: _allUsers, params: []);
    print(val);
    return val[0];
  }

  verifyUser(String address) async {
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _verifyUser,
            parameters: [
              EthereumAddress.fromHex(address),
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  Future<List<dynamic>> userInfo(String address) async {
    notifyListeners();
    final val =
        await _client.call(contract: _contract, function: _userInfo, params: [
      EthereumAddress.fromHex(address),
    ]);
    print(val);
    return val;
  }

  Future<List<dynamic>> myProfileInfo() async {
    notifyListeners();
    final val =
        await _client.call(contract: _contract, function: _userInfo, params: [
      _ownAddress,
    ]);
    print(val);
    return val;
  }

  addLandInspector(String address, String name, String age, String desig,
      String city) async {
    isLoading = true;
    notifyListeners();
    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _addLandInspector,
            parameters: [
              EthereumAddress.fromHex(address),
              name,
              BigInt.parse(age),
              desig,
              city
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }

  isLandInspector(String address) async {
    final val = await _client.call(
        contract: _contract, function: _isLandInspector, params: [_ownAddress]);
    return val[0];
  }

  isUserregistered() async {
    final val = await _client.call(
        contract: _contract,
        function: _isUserRegistered,
        params: [_ownAddress]);
    return val[0];
  }

  registerUser(String name, String age, String city, String adhar, String pan,
      String document, String email) async {
    isLoading = true;
    notifyListeners();

    await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
            contract: _contract,
            function: _registerUser,
            parameters: [
              name,
              BigInt.parse(age),
              city,
              adhar,
              pan,
              document,
              email
            ]),
        chainId: 80001,
        fetchChainIdFromNetworkId: false);
  }
}
