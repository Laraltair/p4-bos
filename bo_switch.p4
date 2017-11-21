#include <core.p4>
#include <v1model.p4>

typedef bit<48> EthernetAddress;
typedef bit<32> IPv4Address;

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16> ethernetType;
}


header IPv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    IPv4Address srcAddr;
    IPv4Address dstAddr;
    //varbit<320>  options;
}

header UDP_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> udplength;
    bit<16> checksum;
}

struct headers {
    Ethernet_h ethernet;
    IPv4_h ipv4;
    UDP_h udp;
}


struct mystruct_t {
    bit<32> a;
}


struct metadata {
    mystruct_t mystruct1;
}

typedef tuple<bit<4>, bit<4>, bit<8>, varbit<56>> myTuple1;

error {
    Ipv4ChecksumError
}


parser bo_Parser(packet_in pkt, out headers hdr, 
                    inout metadata meta, inout standard_metadata_t stdmeta)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethernetType) {
            0x0800 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            0x11 : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

}


control bo_Ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta)
{
    //work token 1, work token 2, standby token 1, standby token 2
    register<bit<32>>(4) rgt;

    bit<32> wt_1_position = 0;
    bit<32> wt_2_position = 1;
    bit<32> st_1_position = 2;
    bit<32> st_2_position = 3;

    bit<32> wt_1 = 0;
    bit<32> wt_2 = 0;
    bit<32> st_1 = 0;
    bit<32> st_2 = 0;

    action forward(bit<9> port) {
        stdmeta.egress_spec = port;
    }

    action read_token_register() {
        rgt.read(wt_1, wt_1_position);
        rgt.read(wt_2, wt_2_position);
        rgt.read(st_1, st_1_position);
        rgt.read(st_2, st_2_position);
    }

    action write_wt_1() {
        rgt.write(wt_1_position, wt_1 > stdmeta.packet_length ? wt_1 - stdmeta.packet_length : 0);
    }

    action write_wt_2() {
        rgt.write(wt_2_position, wt_2 > stdmeta.packet_length ? wt_2 - stdmeta.packet_length : 0);
    }

    action write_st_1() {
        rgt.write(st_1_position, st_1 > stdmeta.packet_length ? st_1 - stdmeta.packet_length : 0);
    }

    action write_st_2() {
        rgt.write(st_2_position, st_2 > stdmeta.packet_length ? st_2 - stdmeta.packet_length : 0);
    }

    table match_inport {
        key = {
            stdmeta.ingress_port:exact;
        }
        actions = {forward;}
    }

    table match_ip_udp {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {forward;}
    }

    table acquire_token {
        actions = {read_token_register;}
    }

    table update_wt_1 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {write_wt_1;}
    }

    table update_wt_2 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {write_wt_2;}
    }

    table update_st_1 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {write_st_1;}
    }

    table update_st_2 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {write_st_2;}
    }

    table work_token_1 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {forward;}
    }

    table work_token_2 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {forward;}
    }
    
    table standby_token_1 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {forward;}
    }

    table standby_token_2 {
        key = {
            hdr.ipv4.dstAddr:exact;
            hdr.udp.dstPort:exact;
        }
        actions = {forward;}
    }

    apply {

        match_inport.apply();

        acquire_token.apply();
        if (hdr.ethernet.ethernetType == 0x0800) {

            match_ip_udp.apply();

            if (wt_1 > 0) {
                work_token_1.apply();
                update_wt_1.apply();
            }
            else if (wt_2 > 0) {
                work_token_2.apply();
                update_wt_2.apply();
            }
            else if (st_1 > 0) {
                standby_token_1.apply();
                update_st_1.apply();
            }
            else if (st_2 > 0) {
                standby_token_2.apply();
                update_st_2.apply();
            }
        }
    }

}



control bo_Egress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta)
{   

    apply {

    }
}

control bo_VerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum(true,
        {   hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr//,hdr.ipv4.options
        },hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control bo_UpdateChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(true,
        {   hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr//,hdr.ipv4.options
        },hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }    
}

control bo_Deparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
    }

}

V1Switch<headers, metadata>(bo_Parser(), bo_VerifyChecksum(), bo_Ingress(), bo_Egress(), bo_UpdateChecksum(),bo_Deparser()) main;