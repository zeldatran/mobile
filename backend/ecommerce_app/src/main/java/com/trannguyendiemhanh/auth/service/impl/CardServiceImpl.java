package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Card;
import com.trannguyendiemhanh.auth.repository.CardRepository;
import com.trannguyendiemhanh.auth.service.CardService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CardServiceImpl extends JpaCrudServiceImpl<Card, UUID> implements CardService {
    public CardServiceImpl(CardRepository repository) {
        super(repository);
    }
}
