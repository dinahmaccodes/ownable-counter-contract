use cohort_4::ownable::{IOwnableDispatcher, IOwnableDispatcherTrait};
use core::num::traits::Zero;
use core::traits::TryInto;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;


fn deploy_ownable_contract() -> IOwnableDispatcher {
    //ownable deployment
    let ownable_contract_name: ByteArray = "Ownable";
    let ownable_contract = declare(ownable_contract_name)
        .expect('ownable contract not working')
        .contract_class();
    let (ownable_contract_address, _) = ownable_contract
        .deploy(@array![OWNER().into()])
        .expect('ownable address issue');
    let ownable = IOwnableDispatcher { contract_address: ownable_contract_address };
    return ownable;
}

//NB: Leave only the tests for ownable here.
//Move the rest to their respective files for test

//Test accounts
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}

fn NON_OWNER() -> ContractAddress {
    'NON_OWNER'.try_into().unwrap()
}

fn NEW_OWNER() -> ContractAddress {
    'NEW_OWNER'.try_into().unwrap()
}
fn zero_address() -> ContractAddress {
    'zero_address'.try_into().unwrap()
}

#[test]
fn test_check_ownable() {
    let ownable = deploy_ownable_contract();
    start_cheat_caller_address(ownable.contract_address, OWNER());
    assert(ownable.get_owner() == OWNER(), 'Oops! not the owner');
}


#[test]
fn test_check_ownable_set_new_owner() {
    let ownable = deploy_ownable_contract();
    start_cheat_caller_address(ownable.contract_address, OWNER());
    assert(ownable.get_owner() == OWNER(), 'Oops! not the owner');
    stop_cheat_caller_address(ownable.contract_address);

    start_cheat_caller_address(ownable.contract_address, OWNER());
    ownable.set_owner(NEW_OWNER());
    assert(ownable.get_owner() == NEW_OWNER(), 'Oops! not the new owner');
    stop_cheat_caller_address(ownable.contract_address);
}

#[test]
#[should_panic(expect: 'Nope! only owner can call this')]
fn test_ownable_should_panic_with_non_owner() {
    let ownable = deploy_ownable_contract();
    start_cheat_caller_address(ownable.contract_address, OWNER());
    assert(ownable.get_owner() == OWNER(), 'Oops! not the owner');
    stop_cheat_caller_address(ownable.contract_address);

    start_cheat_caller_address(ownable.contract_address, OWNER());
    assert(ownable.get_owner() == NON_OWNER(), 'Oops! not the new owner');
    stop_cheat_caller_address(ownable.contract_address);
}
// #[test]
// #[should_panic(expect: 'New owner cant be zero address')]
// fn test_ownable_should_panic_with_non_owner_zero_address() {
//     let ownable = deploy_ownable_contract();
//     start_cheat_caller_address(ownable.contract_address, OWNER());
//     assert(ownable.get_owner() == OWNER(), 'Oops! not the owner');
//     stop_cheat_caller_address(ownable.contract_address);

//     start_cheat_caller_address(ownable.contract_address, OWNER());
//     ownable.set_owner(zero_address());
//     assert(ownable.get_owner() == zero_address(), 'Oops! not the new owner');
//     stop_cheat_caller_address(ownable.contract_address);
// }


