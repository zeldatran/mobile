package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Customer;
import com.trannguyendiemhanh.auth.repository.CustomerRepository;
import com.trannguyendiemhanh.auth.service.CustomerService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CustomerServiceImpl extends JpaCrudServiceImpl<Customer, UUID> implements CustomerService {
    public CustomerServiceImpl(CustomerRepository repository) {
        super(repository);
    }
}
