/*
Token specialiest to Power Delivery in Watt-Hours (Wh)
Issued by a factory for smart clearing

Implements: ERC-20 Token Standard

Challenges of PowerTokens:
=> Additional TimeFrame of Delivery required
=> Only valid for exchange into actual power in TimeFrame

*/

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract PowerToken {
	
	// BP - Token Declaration
	string public standard = 'PowerToken 0.1';
    string public name = "PowerToken";
    string public symbol = "Wh";
    uint8 public decimals = 0;
	uint256 public delivery_start=0;
	uint256 public delivery_end=0;
	
	// Triggered when tokens are transferred.
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	
	// Triggered whenever approve(address _spender, uint256 _value) is called.
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	// Freeze an address 
	event FrozenFunds(address target, bool frozen);
	
	uint256 public totalsupply;
	
	mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
	
	mapping (address => bool) public frozenAccount;
	

	PowerTokenFactory public issuer;
	
	function PowerToken(uint256 _delivery_start,uint256 _delivery_end) {
		issuer = PowerTokenFactory(msg.sender);	
		msg.sender.send(msg.value);
		delivery_start=_delivery_start;
		delivery_end=_delivery_end;
	}
	
    /* Allow another contract to spend some tokens in your behalf */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }
	
    //* A contract attempts to get the coins */	
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        // Check if frozen            
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
	

	/* mint additional Tokens on delivered schedule request */
	function mintToken(address target, uint256 mintedAmount) {
			// not implemented as not required by PowerToken
			throw;
	}
	
	function planFeedIn(uint256 _value) {
		if (balanceOf[msg.sender] + _value < balanceOf[msg.sender]) throw;   // Check for overflows
		if(totalsupply+_value<totalsupply) throw;
		balanceOf[msg.sender]+=_value;
		totalsupply += _value;
		//Transfer(0, msg.sender, _value);
		Transfer(issuer, msg.sender, _value);		
	}
	/* Freeze Account - to be used by Metering after Delivery for balancing */
	function freezeAccount(address target, bool freeze) {
		if(PowerTokenFactory(msg.sender)!=issuer) throw;
		frozenAccount[target] = freeze;
		FrozenFunds(target, freeze);
	}
	
	function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if (frozenAccount[msg.sender]) throw;                // Check if frozen
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
	
    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether
    }
		
}

contract PowerTokenFactory {

	address public owner;
	PowerToken[] public tokens;
	
	function PowerTokenFactory() {
		owner=msg.sender;
	}

	/* Returns PowerTokens evailable for timeSeries or creates new Token if none is available */
	function getTokens(uint256 _delivery_start,uint256 _delivery_end) returns(PowerToken[],uint8) {
		 PowerToken[] memory activeTokens = new PowerToken[](100);
		 uint8 cnt=0;
		 for(var i=0;i<tokens.length;i++) {
				if((tokens[i].delivery_start()>=_delivery_start)&&(tokens[i].delivery_end()<=_delivery_end)) {
					activeTokens[cnt]=tokens[i];
					cnt++;
				}
		 }
		 if(cnt==0) {
				PowerToken newToken = new PowerToken(_delivery_start,_delivery_end);
				tokens.push(newToken);
				activeTokens[cnt]=newToken;	
				cnt++;
		 }
		return (activeTokens,cnt);
	}
	
}	