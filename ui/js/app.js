if (typeof web3 !== 'undefined') {
  // Web3 has been injected by the browser (Mist/MetaMask)
  web3 = new Web3(web3.currentProvider);
} else {
  // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
  web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
}
ptf={};
ptf.obj = [];
ptf.links = [];
ptf.null_addr="0x0000000000000000000000000000000000000000";
function typedLinkBuilder(address,abi) {
	ptf.links[address]=abi;
	return "<a href='#' data-abi='"+abi+"' class='typedLink' title='"+address+"' onclick='openTypedLink(\""+address+"\",\""+abi+"\")'>"+abi+" "+address.substr(36)+"</a>";
}
function render(name,abi) {
var html="";
if(name=="preview") {
	html+="<h3>"+abi+" "+ptf.obj[name].address.substr(36)+"</h3>";
} else {
	html+="<h3>"+name+"</h3>";
}
html+="<h4>"+ptf.obj[name].address+"</h4>";
html+="<table class='table'>";
console.log("ABI:",abi);
if(abi=="PowerTokenFactory") {
	html+="<tr><td>Owner</td><td>"+typedLinkBuilder(ptf.obj[name].owner(),'Account')+"</td></tr>";	
	var i=0;	
	try {
	do {
		if(ptf.obj[name].tokens(i)!=ptf.null_addr) {
			html+="<tr><td></td><td>"+typedLinkBuilder(ptf.obj[name].tokens(i),'PowerToken')+"</td></tr>";
		}
		i++;
	} while(true) 
	} catch(e) {}	
}
if(abi=="PowerToken") {
	html+="<tr><td>Standard</td><td>"+ptf.obj[name].standard()+"</td></tr>";
	html+="<tr><td>Name</td><td>"+ptf.obj[name].name()+"</td></tr>";
	html+="<tr><td>Symbol</td><td>"+ptf.obj[name].symbol()+"</td></tr>";
	html+="<tr><td>Delivery Start</td><td>"+new Date(ptf.obj[name].delivery_start()*1000).toLocaleString()+"</td></tr>";
	html+="<tr><td>Delivery End</td><td>"+new Date(ptf.obj[name].delivery_end()*1000).toLocaleString()+"</td></tr>";
	html+="<tr><td>Total Scheduled</td><td>"+ptf.obj[name].totalsupply()+"</td></tr>";	
	html+="<tr><td>Your Schedule</td><td>"+ptf.obj[name].balanceOf(web3.eth.accounts[0])+"</td></tr>";	
	html+="<tr><td>View Token</td><td><a href='https://ethplorer.io/address/'"+ptf.obj[name].address+"' target=_blank>ETHplorer.io</a>";
	html+="<tr><td>&nbsp;</td><td><button class='btn btn-primary' onclick='schedule("+name+",10)'>Schedule 10</button></td></tr>";
	console.log(name);
}
html+="</table>";
$('#'+name).html(html);
$('#'+name).show();
}


$('#btn_createToken').click(function() {
	var t = new Date().getTime();
	t=t/1000;
	
	ptf.obj.factory.getTokens(t+300,t+600,{from:web3.eth.accounts[0]});
	location.reload(false);
});

function schedule(name,value) {
	ptf.obj.preview.planFeedIn(value,{from:web3.eth.accounts[0]});
	location.reload(false);
}

function loadInstance(abi,address,name) {
	$.getJSON("/build/"+abi+".abi",function(abi_code) {
			var obj = web3.eth.contract(abi_code).at(address);		
			ptf.obj[name]=obj;
			render(name,abi);
			console.log("Loaded ptf.obj."+name);
	});
}

function loadDeployment() {
	$.getJSON("/js/current.deployment.json",function(data) {
		ptf.deployment=data;	
		loadInstance('PowerTokenFactory',data.powertokenfactory,"factory");		
	});
}
function openTypedLink(address,abi) {
	if(abi=="Account") {
		$('#preview').html("<h3>Account</h3><h4>"+address+"</h4>");
	} else {
		loadInstance(abi,address,"preview");
	}
}
loadDeployment();
setInterval(function() {
	$('#clock').html(new Date().toLocaleString());
},10000);