pragma solidity ^0.5.12;

contract SupplyChain {



    struct Receipt{

        bytes32 receiptID; //收据标识id

        address from; //欠款公司

        address to; //收款公司

        uint amount; //欠款金额

        uint status; //状态（数字代表有多少家银行确认）

        uint time; //到账时间

    }



    struct Company{

        string name; //公司名字

        address companyAddress; //公司地址

        bool nature; //公司性质（企业为0，银行为1）

        bytes32 confirmPassword; //确认密码

    }



    mapping(address => Company) private companys; //将地址映射为公司



    mapping(address => Receipt[]) private receipts; //欠款公司的收据



    event newCompanyEvent(string _name, address _addr, bool _nature, bytes32 random);

    event newReceiptEvent(bytes32 _ID, address _from, address _to, uint _amount, uint _status, uint _time);

    event transferEvent(bytes32 _ID, address _from, address _to, uint _amount, uint _status, uint _time);

    event financingEvent(bytes32 _ID, address _from, address _bank, uint _amount, uint _status, uint _time);

    event settleEvent();

    

    //辅助函数，将uint转为bytes

    function toBytes(uint256 x) public returns (bytes memory b) {

        b = new bytes(32);

        assembly { mstore(add(b, 32), x) }

    }



    //传入公司名字和性质来定义一个公司

    function newCompany(string memory _name, bool _nature, uint randNonce) public returns(bytes32 ){

        bytes32 random = keccak256(toBytes(now + uint(msg.sender) + randNonce));

        companys[msg.sender] = Company(_name, msg.sender, _nature, random);

        emit newCompanyEvent(_name, msg.sender, _nature, random);

        return random;

    }



    //传入收款公司，欠款金额和到账时间(到账时间为多少天后到期)来定义一个收据，交易上链

    function newReceipt(address _to, uint _amount, uint _time) public returns(bytes32){

        if(msg.sender != _to){

            bytes32 tempID = keccak256(toBytes(now + uint(msg.sender)));

            uint timeTemp = now + _time * 1 days;

            Receipt memory tempReceipt = Receipt(tempID, msg.sender, _to, _amount, 0, timeTemp);

            receipts[msg.sender].push(tempReceipt);

            emit newReceiptEvent(tempID, msg.sender, _to, _amount, 0, timeTemp);

            return tempID;

        }

        else{

            revert("Sorry! You have no right to create a receipt!");

        }

    }



    //通过id和地址确认收据是否存在

    function verifyReceipt(bytes32 _id, address _from) private returns(bool){

        for(uint i=0; i<receipts[_from].length; ++i){

            if (_id == receipts[_from][i].receiptID){

                return true;

            }

        }

        return false;

    }



    //传入收据id，欠款公司，收款公司，欠款金额来进行转让，转让上链

    function transfer(bytes32 _id, address _from, address _to, uint _amount) public returns(bytes32){

        if(msg.sender != _to && verifyReceipt(_id, _from)){

            for(uint i=0; i<receipts[_from].length; ++i){

                if (_id == receipts[_from][i].receiptID && receipts[_from][i].to == msg.sender && _amount <= receipts[_from][i].amount){

                    receipts[_from][i].amount -= _amount;

                    bytes32 tempID = keccak256(toBytes(now + uint(_from)));

                    Receipt memory tempReceipt = Receipt(tempID, _from, _to, _amount, 0, receipts[_from][i].time);

                    receipts[_from].push(tempReceipt);

                    emit transferEvent(tempID, _from, _to, _amount, 0, receipts[_from][i].time);

                    return tempID;

                }

            }

        }

        else{

            revert("Sorry! You have no right to transfer the receipt!");

        }

    }



    //传入收据id，欠款公司，银行来进行融资，融资上链

    function financing(bytes32 _id, address _from, address _bank) public returns(bytes32){

        if(msg.sender != _bank && verifyReceipt(_id, _from) && companys[_bank].nature){

            for(uint i=0; i<receipts[_from].length; ++i){

                if (_id == receipts[_from][i].receiptID && receipts[_from][i].to == msg.sender){

                    bytes32 tempID = keccak256(toBytes(now + uint(_from) + 1));

                    Receipt memory tempReceipt = Receipt(tempID, _from, _bank, receipts[_from][i].amount, 0, receipts[_from][i].time);

                    receipts[_from].push(tempReceipt);

                    delete receipts[_from][i];

                    emit financingEvent(tempID, _from, _bank, receipts[_from][i].amount, 0, receipts[_from][i].time);

                    return tempID;

                }

            }

        }

        else{

            revert("Sorry! You have no right to finance!");

        }

    }



    //传入收据id，收款公司确认密码来进行结算，结算上链

    function settle(bytes32 _id, bytes32 _confirmPassword) public {

        if(verifyReceipt(_id, msg.sender)){

            for(uint i=0; i<receipts[msg.sender].length; ++i){

                if (_id == receipts[msg.sender][i].receiptID && companys[receipts[msg.sender][i].to].confirmPassword == _confirmPassword){

                    delete receipts[msg.sender][i];

                    emit settleEvent();

                    return;

                }

            }

        }

        else{

            revert("Sorry! You have no right to settle the receipt!");

        }

    }

}

