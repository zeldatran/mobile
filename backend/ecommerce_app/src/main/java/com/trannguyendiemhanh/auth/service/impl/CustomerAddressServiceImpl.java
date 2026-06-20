package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.CustomerAddress;
import com.trannguyendiemhanh.auth.repository.CustomerAddressRepository;
import com.trannguyendiemhanh.auth.service.CustomerAddressService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CustomerAddressServiceImpl extends JpaCrudServiceImpl<CustomerAddress, UUID> implements CustomerAddressService {
    public CustomerAddressServiceImpl(CustomerAddressRepository repository) {
        super(repository);
    }
}
