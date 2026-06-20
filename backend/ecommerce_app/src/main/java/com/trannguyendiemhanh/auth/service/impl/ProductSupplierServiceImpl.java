package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductSupplier;
import com.trannguyendiemhanh.auth.repository.ProductSupplierRepository;
import com.trannguyendiemhanh.auth.service.ProductSupplierService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProductSupplierServiceImpl extends JpaCrudServiceImpl<ProductSupplier, UUID> implements ProductSupplierService {
    public ProductSupplierServiceImpl(ProductSupplierRepository repository) {
        super(repository);
    }
}
