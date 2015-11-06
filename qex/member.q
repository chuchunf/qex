/****************************************************
/Process handler, member management, broadcast and unicast
/****************************************************
\d .member

members : `int$()!`int$()               / empty member dictionary
memberid: 0                             / placeholder for member id

/*******************************************************
/ Process handler of broker connections         
/ .z.pw handle password, username as symbol, password as char list        
.z.pw: {[username;password]
        if[not .qex.ready; :0b];
        memberid:: first exec id from .schema.Members where name=username, md5sum=`$raze string -15!password;
        if[(`.[`STARTTIME]>`hh$.z.Z) or (`.[`ENDTIME]-1)<`hh$.z.Z; :0b]

        $[memberid>0; :1b; :0b]
    }
    
.z.po: {[pid]
       members[pid]: memberid
    }

.z.pc: {[pid]
       members:: members _ pid;
    }

/*******************************************************
/get member id by process id and vice versa
GetMember : {
        :members[.z.w];
    }
GetHandler: {[mid]
        :members ? mid;
    }

/*******************************************************
/Communication with (notify) member clients
/Unicast trade details to buyer and seller only
UniCast : {[trades]
        {[trades; members; handler]
            feed: delete buyerid, sellerid from select from trades where buyerid=members[handler] or sellerid=members[handler];
            if[count feed; 
                result : -1 _ raze (string value exec from feed) ,' ",";
                (neg handler) (0N!; result)];
        } [trades;members;] each key members
    }

/Boradcast quotation to all connected members
BroadCast : {[quote] 
        {[quote; handler]
            result : -1 _ raze (string value exec from quote) ,' ",";
            (neg handler) (0N!; result);
        } [quote;] each key members
    } 

/*******************************************************
/ Member management
AddMember : {[member]
        `.schema.Members insert (member[`id]; `$member[`name]; `$raze string -15!member[`pass]; member[`mm]);
        `.[`MEMBERS] set .schema.Members;
    }

DelMember : {[id]
        delete from `.schema.Members where id=id;
        `.[`MEMBERS] set .schema.Members;        
    }
    
ListMember: {
        select from .schema.Members;
    }
    
\d .
