package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Supplier;
import com.trannguyendiemhanh.auth.repository.SupplierRepository;
import com.trannguyendiemhanh.auth.service.SupplierService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class SupplierServiceImpl extends JpaCrudServiceImpl<Supplier, UUID> implements SupplierService {
    public SupplierServiceImpl(SupplierRepository repository) {
        super(repository);
    }
}
