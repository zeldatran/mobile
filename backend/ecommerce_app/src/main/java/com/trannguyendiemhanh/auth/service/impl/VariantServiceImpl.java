package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Variant;
import com.trannguyendiemhanh.auth.repository.VariantRepository;
import com.trannguyendiemhanh.auth.service.VariantService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class VariantServiceImpl extends JpaCrudServiceImpl<Variant, UUID> implements VariantService {
    public VariantServiceImpl(VariantRepository repository) {
        super(repository);
    }
}
