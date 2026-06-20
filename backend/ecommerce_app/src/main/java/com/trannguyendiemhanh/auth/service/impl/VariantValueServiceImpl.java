package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.VariantValue;
import com.trannguyendiemhanh.auth.repository.VariantValueRepository;
import com.trannguyendiemhanh.auth.service.VariantValueService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class VariantValueServiceImpl extends JpaCrudServiceImpl<VariantValue, UUID> implements VariantValueService {
    public VariantValueServiceImpl(VariantValueRepository repository) {
        super(repository);
    }
}
