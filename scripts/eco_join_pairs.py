import sys
sys.path.insert(0, "/users/PUOM0008/crsfaaron")
exec(open("/users/PUOM0008/crsfaaron/eco_join.py").read().split('process("/users/PUOM0008/crsfaaron/magplot/magp_sites_nb_ns.csv"')[0])
process("/users/PUOM0008/crsfaaron/magplot/verify/magp_qcnb_pairs.csv", "lon", "lat",
        ["STAND","PROV"], "/users/PUOM0008/crsfaaron/magplot/verify/magp_qcnb_ecol3.csv")
print("DONE_ECO_JOIN_PAIRS")
